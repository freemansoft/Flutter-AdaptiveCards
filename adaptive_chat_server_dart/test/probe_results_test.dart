import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_results.dart';

// probe_results.dart's own doc comment explains the stakes: every figure in
// ModelBehavior.md used to be hand-transcribed from a probe's console
// output, which made a typo invisible and a re-run undiffable. This suite is
// mostly the schema/data-model genre check_results_test.dart names
// explicitly -- the 'round trip' group is a JSON (de)serialization check
// against committed result-file shapes (including that an old file recorded
// before a field existed must still parse), and 'model slug' checks a pure
// string mapping used to name result directories. It is not, however,
// entirely that genre: 'cards versus prose', 'split cases', and 'latency'
// exercise real derived-figure logic (medianMs's first-call-is-a-cold-load
// rule, splitCases' per-condition grouping) that a probe's own summary
// depends on, and 'ollama version detection' / 'machine detection' run the
// actual host-detection functions against this machine, which is closer to
// a smoke test than either genre above.
ProbeCall call(
  String id, {
  bool pass = true,
  String label = 'card[2]',
  int? ms,
  String? cond,
}) => ProbeCall(
  caseId: id,
  sample: 0,
  pass: pass,
  label: label,
  ms: ms,
  condition: cond,
);

ProbeRun runWith(List<ProbeCall> calls) => ProbeRun(
  probe: 'shape_ab',
  model: 'qwen3.8:27b-nvfp4',
  measuredAt: '2026-08-20',
  samples: 2,
  assets: const {'card_system_prompt.txt': 'abc123def456'},
  calls: calls,
);

void main() {
  group('model slug', () {
    // `:` and `/` are both legal in an Ollama tag and both illegal (or
    // meaningful) in a path; this pins the exact replacement scheme rather
    // than letting it drift into something the archive on disk was not
    // written with.
    test('strips the characters a path cannot carry', () {
      expect(modelSlug('qwen3.8:27b-nvfp4'), 'qwen3.8_27b-nvfp4');
      expect(
        modelSlug('hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest'),
        'hf.co__unsloth__Nemotron-3-Nano-30B-A3B-GGUF_latest',
      );
    });

    // modelSlug's doc comment admits the mapping is "deliberately
    // lossy-looking" -- this is what backs that claim against every tag
    // actually probed, since two tags colliding on one directory would
    // silently merge their results.
    test('is injective across the tags in use', () {
      const tags = [
        'gpt-oss:20b',
        'granite4.1:3b',
        'granite4.1:8b',
        'llama3-chatqa:8b',
        'llama3-groq-tool-use:8b',
        'llama3.2:latest',
        'nemotron-3-nano:4b',
        'nemotron-3-nano:30b',
        'nemotron-3.5-lightning:30b',
        'qwen2.5-coder:7b',
        'qwen3-coder:30b',
        'qwen3.5:9b',
        'qwen3.6:27b-coding-nvfp4',
        'qwen3.8:27b-nvfp4',
        'hf.co/unsloth/Nemotron-3-Nano-30B-A3B-GGUF:latest',
      ];
      expect(tags.map(modelSlug).toSet(), hasLength(tags.length));
    });
  });

  group('cards versus prose', () {
    test('separates the two kinds of pass the score conflates', () {
      // The exact shape of qwen3.8's stress sweep: 5/5, but four of the ten
      // cells were prose. A pass count alone cannot show that.
      final run = runWith([
        call('codeblock'),
        call('bigtable'),
        call('nested', label: 'prose'),
        call('multiline', label: 'prose'),
        call('mixed'),
      ]);
      expect(run.score, (5, 5));
      expect(run.cardsAndProse, (3, 2));
    });

    // `prose-ok` is a second, shape-probe-specific spelling of "clean prose"
    // alongside plain `prose`; isProse must recognise both, or a whole
    // probe's cards-vs-prose split would silently misclassify one label as
    // neither.
    test('counts the shape probe prose-ok label as prose', () {
      expect(runWith([call('prose', label: 'prose-ok')]).cardsAndProse, (0, 1));
    });
  });

  group('split cases', () {
    test('names a case whose samples disagree', () {
      final run = runWith([
        const ProbeCall(
          caseId: 'table',
          sample: 0,
          pass: true,
          label: 'card[1]',
          condition: 'warm',
        ),
        const ProbeCall(
          caseId: 'table',
          sample: 1,
          pass: false,
          label: 'wrong-shape',
          condition: 'warm',
        ),
        const ProbeCall(
          caseId: 'facts',
          sample: 0,
          pass: true,
          label: 'card[1]',
          condition: 'warm',
        ),
        const ProbeCall(
          caseId: 'facts',
          sample: 1,
          pass: true,
          label: 'card[1]',
          condition: 'warm',
        ),
      ]);
      // `table` rests on one call of two; `facts` is unanimous.
      expect(run.splitCases, ['table']);
    });

    test('does not merge the same case across conditions', () {
      // Passing cold and failing warm is erosion, not sampling noise, and
      // must not be reported as a split.
      final run = runWith([
        const ProbeCall(
          caseId: 'table',
          sample: 0,
          pass: true,
          label: 'card[1]',
          condition: 'cold',
        ),
        const ProbeCall(
          caseId: 'table',
          sample: 0,
          pass: false,
          label: 'wrong-shape',
          condition: 'warm',
        ),
      ]);
      expect(run.splitCases, isEmpty);
    });
  });

  group('latency', () {
    test('median drops the first call, which carries the model load', () {
      final run = runWith([
        call('a', ms: 51410), // cold load
        call('b', ms: 7000),
        call('c', ms: 8000),
        call('d', ms: 9000),
      ]);
      expect(run.medianMs, 8000);
      expect(run.totalMs, 75410);
    });

    test('excludes stalled calls, which measure the ceiling not the model', () {
      // A model that stalls a lot would otherwise report a median of exactly
      // the timeout, which says nothing about how fast it is when it works.
      final run = runWith([
        call('a', ms: 40000), // cold load, dropped as the first call
        call('b', ms: 3000),
        call('c', ms: 120000, pass: false, label: 'broken: timeout (120s)'),
        call('d', ms: 120000, pass: false, label: 'broken: timeout (120s)'),
        call('e', ms: 5000),
      ]);
      expect(run.medianMs, 5000);
      expect(run.timeouts, 2);
      // Total keeps them: that is real wall clock somebody waited through.
      expect(run.totalMs, 288000);
    });

    // A single call with no `ms` leaves both getters with nothing to
    // report -- medianMs because skip(1) drops the only call as the
    // presumed cold load, totalMs because there is no timed call at all --
    // and both must read as null rather than 0, which would look like a
    // real, suspiciously instantaneous measurement.
    test('is null when no call recorded a time', () {
      expect(runWith([call('a')]).medianMs, isNull);
      expect(runWith([call('a')]).totalMs, isNull);
    });
  });

  group('round trip', () {
    // Every optional field populated at once, including the ones that only
    // appeared after the format's first version (variant, machine, ollama,
    // temperature, summary, notes) -- a field silently dropped by toJson or
    // fromJson would otherwise only be noticed by diffing a real result
    // file after the fact.
    test('survives JSON without losing a field', () {
      final run = ProbeRun(
        probe: 'shape_ab',
        model: 'qwen3.8:27b-nvfp4',
        variant: 'unaided',
        measuredAt: '2026-08-20',
        machine: 'Apple M1 Max / 64 GB',
        ollama: '0.33.1',
        samples: 2,
        temperature: 0,
        assets: const {'card_system_prompt.txt': 'abc123def456'},
        summary: const {'coldStart': 23, 'withHistory': 24},
        notes: 'backfilled',
        calls: [call('date', ms: 1200, cond: 'cold')],
      );
      final back = ProbeRun.fromJson(run.toJson());
      expect(back.toJson(), run.toJson());
      expect(back.variant, 'unaided');
      expect(back.machine, 'Apple M1 Max / 64 GB');
      expect(back.ollama, '0.33.1');
      expect(back.calls.single.condition, 'cold');
    });

    test('reads a run recorded before the version was stamped', () {
      // The archive holds 113 of these. A new field must not make them
      // unreadable, or check_results.dart stops being able to police them.
      final legacy = <String, dynamic>{
        'probe': 'shape_ab',
        'model': 'qwen2.5-coder:7b',
        'measuredAt': '2026-08-20',
        'machine': 'Apple M1 Max / 64 GB',
        'samples': 2,
        'assets': {'card_system_prompt.txt': 'abc123def456'},
        'summary': <String, dynamic>{},
        'calls': [
          {'case': 'date', 'sample': 0, 'pass': true, 'label': 'card[2]'},
        ],
      };
      final run = ProbeRun.fromJson(legacy);
      expect(run.ollama, isNull);
      // Absent rather than null-valued: an unstamped run should read as "not
      // recorded", which is true, where an explicit null invites being read
      // as a measured absence.
      expect(run.toJson().containsKey('ollama'), isFalse);
    });
  });

  group('ollama version detection', () {
    // Runs the real detectOllamaVersion() against whatever `ollama` is on
    // this machine's PATH rather than a fake -- CI has no Ollama installed,
    // so the only thing assertable here is the shape of a version when one
    // is found, not that one is always found.
    test('reads a version, or reports that it could not', () {
      final v = detectOllamaVersion();
      if (v != null) {
        expect(v, matches(r'^\d+\.\d+\.\d+$'));
      }
    });
  });

  group('machine detection', () {
    // Runs the real detectMachine() against whatever host the test happens
    // to execute on. The macOS-specific assertions exist because every
    // recorded measurement in this directory has been taken on a Mac; on
    // any other OS this only checks the non-empty fallback, per
    // detectMachine's doc comment ("wrong-but-honest beats a confident
    // guess").
    test('names this host rather than returning a placeholder', () {
      final m = detectMachine();
      expect(m, isNotEmpty);
      if (Platform.isMacOS) {
        expect(m, contains('Apple'));
        expect(m, contains('GB'));
      }
    });
  });
}
