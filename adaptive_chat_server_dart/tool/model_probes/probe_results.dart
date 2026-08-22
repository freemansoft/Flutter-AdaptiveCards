/// Machine-readable probe output, so a measurement outlives the terminal it
/// was printed in.
///
/// Every number in [`ModelBehavior.md`](../../ModelBehavior.md) was, until
/// this file existed, hand-transcribed from a probe's console output into a
/// Markdown table. That is unauditable in three separate ways: a typo is
/// invisible, a re-run cannot be diffed against the original, and a number
/// carries no record of *which* system prompt produced it — even though the
/// card prompt has been edited repeatedly and every edit ages every result in
/// the file.
///
/// A [ProbeRun] fixes all three by writing the run to JSON: the per-call
/// detail so a summary can be re-derived rather than trusted, and the digests
/// of the prompt assets the run actually used so staleness is detectable
/// without re-running anything. `check_results.dart` reads these files in CI,
/// which is the point — the CI server cannot run a model, but it can check
/// what a model run recorded.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// One `/api/chat` call and how the server's own judge scored it.
class ProbeCall {
  /// Creates a call record.
  const ProbeCall({
    required this.caseId,
    required this.sample,
    required this.pass,
    required this.label,
    this.condition,
    this.setting,
    this.ms,
  });

  /// Rebuilds a call from its JSON form.
  factory ProbeCall.fromJson(Map<String, dynamic> json) => ProbeCall(
    caseId: json['case'] as String,
    sample: json['sample'] as int,
    pass: json['pass'] as bool,
    label: json['label'] as String,
    condition: json['condition'] as String?,
    setting: json['setting'] as String?,
    ms: json['ms'] as int?,
  );

  /// The case this call exercised (`table`, `choice1`, …).
  final String caseId;

  /// Which repeat of that case this was, zero-based.
  final int sample;

  /// The server's verdict — a renderable card, or clean prose.
  final bool pass;

  /// The verdict detail (`card[2]`, `prose`, `wrong-shape: …`).
  ///
  /// Kept verbatim because it carries the distinction a pass count erases: a
  /// stress cell scored `PASS` is a card *or* prose, and which one it was is
  /// the difference between "the model answered well" and "the model stopped
  /// producing cards". See `cardsAndProse`.
  final String label;

  /// Cold-start versus with-history, where the probe measures both.
  final String? condition;

  /// The decoding setting, where the probe sweeps several.
  final String? setting;

  /// Wall-clock for the call, including a model load on the first one.
  final int? ms;

  /// Whether the reply was a card rather than prose.
  bool get isCard => label.startsWith('card[');

  /// Whether the reply was prose the judge accepted.
  bool get isProse => label == 'prose' || label == 'prose-ok';

  /// Whether the call hit the per-call ceiling rather than returning.
  ///
  /// The label can arrive wrapped — the shape judge reports a stalled call as
  /// `broken: timeout (120s)` — so this matches anywhere in the string rather
  /// than at the start.
  bool get isTimeout => label.contains('timeout (');

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'case': caseId,
    'sample': sample,
    'pass': pass,
    'label': label,
    if (condition != null) 'condition': condition,
    if (setting != null) 'setting': setting,
    if (ms != null) 'ms': ms,
  };
}

/// A complete probe run: what was measured, against what, and every call.
class ProbeRun {
  /// Creates a run record.
  const ProbeRun({
    required this.probe,
    required this.model,
    required this.measuredAt,
    required this.samples,
    required this.assets,
    required this.calls,
    this.machine,
    this.variant,
    this.temperature,
    this.summary = const {},
    this.notes,
  });

  /// Rebuilds a run from its JSON form.
  factory ProbeRun.fromJson(Map<String, dynamic> json) => ProbeRun(
    probe: json['probe'] as String,
    model: json['model'] as String,
    measuredAt: json['measuredAt'] as String,
    samples: json['samples'] as int,
    assets: Map<String, String>.from(json['assets'] as Map),
    calls: [
      for (final c in json['calls'] as List)
        ProbeCall.fromJson(c as Map<String, dynamic>),
    ],
    machine: json['machine'] as String?,
    variant: json['variant'] as String?,
    temperature: (json['temperature'] as num?)?.toDouble(),
    summary: Map<String, dynamic>.from(
      (json['summary'] as Map?) ?? const <String, dynamic>{},
    ),
    notes: json['notes'] as String?,
  );

  /// Reads a run from a JSON file.
  factory ProbeRun.read(File file) => ProbeRun.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );

  /// Which script produced this (`shape_ab`, `cascade_ab`, …).
  final String probe;

  /// The Ollama model tag, verbatim.
  final String model;

  /// `YYYY-MM-DD` the run was taken.
  final String measuredAt;

  /// Repeats per case.
  final int samples;

  /// Digests of the prompt assets this run used, by asset name.
  ///
  /// This is what makes staleness detectable without a model: if
  /// `assets/card_system_prompt.txt` is edited, every stored run still names
  /// the digest it was measured against, so a checker can say which recorded
  /// results have quietly become historical.
  final Map<String, String> assets;

  /// The host the run was taken on, e.g. `Apple M1 Max / 64 GB`.
  ///
  /// Stamped into every result because latency is a property of the pair, not
  /// of the model. A column that silently mixed two Macs would be worse than
  /// no column, and this file is the only place that can rule it out.
  final String? machine;

  /// A distinguishing label where one probe is run two ways.
  ///
  /// `shape_ab` is the case that needs it: the same script produces the
  /// as-shipped number with the card seed and the seed-dependence baseline
  /// without it, and conflating those two would be conflating what a user
  /// gets with what the seed is worth.
  final String? variant;

  /// The temperature, where the probe fixes one.
  final double? temperature;

  /// Per-call detail, in the order the probe made the calls.
  final List<ProbeCall> calls;

  /// Headline figures, as the probe itself reported them.
  ///
  /// Stored rather than only derived so a reader can spot a probe whose
  /// printed summary disagrees with its own calls — which is exactly the
  /// class of error hand-transcription hides.
  final Map<String, dynamic> summary;

  /// Anything about the run a number cannot carry.
  final String? notes;

  /// Passes and total.
  (int, int) get score => (calls.where((c) => c.pass).length, calls.length);

  /// Median call latency in ms, excluding the first call.
  ///
  /// The first call after a model load costs roughly **6-7x** a warm one
  /// (51s against 8s, measured 2026-08-20), which is a large enough outlier
  /// to move any aggregate on its own. It is dropped by rule rather than by
  /// running the whole sweep twice and taking the minimum: the load cost is a
  /// known, identifiable event, so discarding it directly gets the same
  /// answer without paying for a second run — and on a laptop a second
  /// back-to-back run is measured on a hotter, throttling machine anyway, so
  /// min-of-two would trade one uncontrolled bias for another.
  ///
  /// Comparable across models only when the case set is identical, which is
  /// why the latency figures quoted in `ModelBehavior.md` come from the fixed
  /// 25-case shape sweep. Spread within a run is dominated by case mix — a
  /// short rating and a twelve-month table legitimately differ ~20x — not by
  /// machine noise.
  int? get medianMs {
    final v =
        calls
            .skip(1)
            .where((c) => !c.isTimeout)
            .map((c) => c.ms)
            .whereType<int>()
            .toList()
          ..sort();
    if (v.isEmpty) return null;
    return v[v.length ~/ 2];
  }

  /// Calls that hit the ceiling instead of returning.
  ///
  /// Reported beside the latency rather than folded into it: a model that
  /// stalls often is making a real statement about itself, but it is a
  /// different statement from "this model is slow", and averaging the two
  /// together would let the ceiling masquerade as a measurement.
  int get timeouts => calls.where((c) => c.isTimeout).length;

  /// Total time across every recorded call, including the model load and any
  /// time spent stalled.
  ///
  /// The "how long will this sweep take me" number, as opposed to
  /// [medianMs], which is the one comparable between models. Timeouts are
  /// deliberately included here — they are real wall clock somebody waited.
  int? get totalMs {
    final v = calls.map((c) => c.ms).whereType<int>();
    return v.isEmpty ? null : v.reduce((a, b) => a + b);
  }

  /// Cards and prose among the passing calls.
  ///
  /// The distinction the pass rule deliberately erases. `ProbeOutcome.ok` is
  /// true for a renderable card *and* for clean prose, because the card
  /// prompt permits a Markdown answer and only a broken card is a failure.
  /// That is right for "did anything break" and wrong for "is this model
  /// still producing cards" — a model can sweep a set 5/5 while answering
  /// most of it in prose, which is the failure `shape_ab.dart` was written
  /// to catch and which the other sets still cannot see.
  (int, int) get cardsAndProse => (
    calls.where((c) => c.pass && c.isCard).length,
    calls.where((c) => c.pass && c.isProse).length,
  );

  /// Case ids whose samples disagree, i.e. findings resting on one call.
  ///
  /// At `--samples 2` a case that passes once and fails once is reported by
  /// the probe as a failure, and reads in a table exactly like a case that
  /// failed twice. Naming the split ones keeps a coin flip from being quoted
  /// as a measurement.
  List<String> get splitCases {
    final byKey = <String, List<bool>>{};
    for (final c in calls) {
      byKey
          .putIfAbsent('${c.condition ?? ''}/${c.caseId}', () => [])
          .add(c.pass);
    }
    final split = <String>{};
    for (final entry in byKey.entries) {
      if (entry.value.toSet().length > 1) {
        split.add(entry.key.split('/').last);
      }
    }
    return split.toList()..sort();
  }

  /// JSON form, stable-ordered so a re-run diffs cleanly.
  Map<String, dynamic> toJson() => {
    'probe': probe,
    'model': model,
    if (variant != null) 'variant': variant,
    'measuredAt': measuredAt,
    if (machine != null) 'machine': machine,
    'samples': samples,
    if (temperature != null) 'temperature': temperature,
    'assets': assets,
    'summary': summary,
    if (notes != null) 'notes': notes,
    'calls': [for (final c in calls) c.toJson()],
  };

  /// Writes the run to [file], creating parent directories.
  void write(File file) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n',
    );
  }
}

/// Best-effort description of the host, so a run never has to be labeled by
/// hand.
///
/// Reads the CPU brand and physical memory from `sysctl` on macOS, which is
/// where every measurement in this file has been taken. Anywhere else it
/// falls back to the OS name — wrong-but-honest beats a confident guess, and
/// a null would be indistinguishable from "nobody recorded it".
String detectMachine() {
  if (!Platform.isMacOS) return Platform.operatingSystem;
  try {
    final cpu = Process.runSync('sysctl', ['-n', 'machdep.cpu.brand_string']);
    final mem = Process.runSync('sysctl', ['-n', 'hw.memsize']);
    final brand = (cpu.stdout as String).trim();
    final bytes = int.tryParse((mem.stdout as String).trim());
    if (brand.isEmpty) return Platform.operatingSystem;
    if (bytes == null) return brand;
    return '$brand / ${(bytes / (1 << 30)).round()} GB';
  } on ProcessException {
    return Platform.operatingSystem;
  }
}

/// Builds and writes a run, given the calls a probe collected.
///
/// Centralised so every probe stamps the same things — host, asset digests,
/// date — rather than each one remembering to. A probe that recorded its
/// result but not the prompt it was measured against would defeat the whole
/// point of recording it.
void writeProbeRun({
  required String path,
  required String probe,
  required String model,
  required int samples,
  required String assetsDir,
  required List<ProbeCall> calls,
  String? variant,
  double? temperature,
  Map<String, dynamic> summary = const {},
  String? notes,
  List<String> assetNames = defaultProbeAssetNames,
}) {
  final run = ProbeRun(
    probe: probe,
    model: model,
    variant: variant,
    measuredAt: DateTime.now().toIso8601String().split('T').first,
    machine: detectMachine(),
    samples: samples,
    temperature: temperature,
    assets: currentAssetDigests(assetsDir, assetNames: assetNames),
    summary: summary,
    notes: notes,
    calls: calls,
  )..write(File(path));
  final median = run.medianMs;
  stdout.writeln(
    '\nwrote $path  (${calls.length} calls'
    '${median == null ? '' : ', median ${median}ms/call'}'
    ', total ${((run.totalMs ?? 0) / 1000).round()}s, on ${run.machine})',
  );
}

/// Counts passing calls, and splits them into cards and prose.
///
/// The split is the part a bare pass count cannot express: `ok` is true for a
/// renderable card *and* for clean prose, so a set can be swept while most of
/// it was answered in Markdown.
Map<String, dynamic> passSummary(List<ProbeCall> calls) {
  final passed = calls.where((c) => c.pass).toList();
  return {
    'calls': calls.length,
    'passed': passed.length,
    'cards': passed.where((c) => c.isCard).length,
    'prose': passed.where((c) => c.isProse).length,
  };
}

/// Turns a model tag into something usable as a directory name.
///
/// Tags carry `:` and `/` (`hf.co/unsloth/…:latest`), neither of which belongs
/// in a path. The mapping is deliberately lossy-looking but injective for the
/// tags in use, and the untouched tag is stored inside the file, so the
/// directory name is a convenience and never the source of truth.
String modelSlug(String model) =>
    model.replaceAll('/', '__').replaceAll(':', '_');

/// First twelve hex characters of the file's SHA-256, or `null` if absent.
///
/// Twelve is plenty to detect an edit and short enough to read in a diff.
String? assetDigest(File file) {
  if (!file.existsSync()) return null;
  return sha256.convert(file.readAsBytesSync()).toString().substring(0, 12);
}

/// The two assets every probe except `tool_call_probe` sends: the card
/// system prompt and the seed card.
const defaultProbeAssetNames = ['card_system_prompt.txt', 'seed_card.json'];

/// Digests of the prompt assets a probe run depends on.
///
/// [assetNames] defaults to [defaultProbeAssetNames] — the pair every probe
/// except `tool_call_probe` sends. `tool_call_probe` runs unseeded against
/// `card_tool_prompt.txt` instead, so it passes its own list; without that,
/// a recorded digest would name assets the run never sent and omit the one
/// it did, which is what happened before this parameter existed.
///
/// Read from the same place the server reads them, so a recorded digest is a
/// fact about what was actually sent.
Map<String, String> currentAssetDigests(
  String assetsDir, {
  List<String> assetNames = defaultProbeAssetNames,
}) {
  final out = <String, String>{};
  for (final name in assetNames) {
    final digest = assetDigest(File(p.join(assetsDir, name)));
    if (digest != null) out[name] = digest;
  }
  return out;
}

/// Where a run belongs on disk: `results/<model-slug>/<probe>[-variant].json`.
File resultFile(String resultsDir, ProbeRun run) => File(
  p.join(
    resultsDir,
    modelSlug(run.model),
    '${run.probe}${run.variant == null ? '' : '-${run.variant}'}.json',
  ),
);

/// Every recorded run under [resultsDir], in a stable order.
List<ProbeRun> readAllResults(String resultsDir) {
  final dir = Directory(resultsDir);
  if (!dir.existsSync()) return const [];
  final files =
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [for (final f in files) ProbeRun.read(f)];
}
