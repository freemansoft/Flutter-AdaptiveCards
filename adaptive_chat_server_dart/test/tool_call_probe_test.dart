import 'package:test/test.dart';

// Relative: the probe lives outside lib/, so there is no package: URI.
import '../tool/model_probes/tool_call_probe.dart';

// Not a test of app/library behavior: tool_call_probe.dart is a manual CLI
// tool a human runs against a live Ollama model to check whether its chat
// template supports tool calling at all (see the file's own doc comment).
// That probe itself needs a running Ollama and is never exercised in CI —
// what's tested here is only classifyToolSupport, the pure decision table
// that reduces its three independently-fallible probe signals
// (trivial-tool call, card-tool call, renderable arguments, over-calling on
// a prose question) to one ToolVerdict. Guards the precedence between those
// signals, which is easy to get backwards silently: e.g. a template with no
// tool support at all must read as "unsupported" even if a stray positive
// signal appears elsewhere in the same run.
void main() {
  group('classifyToolSupport', () {
    test('a model that does everything right is supported', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: true,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.supported,
      );
    });

    test('a template without tool support is unsupported', () {
      // The discriminator: it could not call even the trivial tool, so
      // "declined" is ruled out.
      expect(
        classifyToolSupport(
          calledTrivialTool: false,
          calledCardTool: false,
          cardArgumentsRender: false,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.unsupported,
      );
    });

    // Guards the precedence, not just the individual values: a false
    // calledTrivialTool must short-circuit to unsupported even when the
    // other three signals look like a pass — an inconsistent probe run
    // (e.g. a flaky model call) must not read as success.
    test('unsupported wins even if a card tool call somehow appeared', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: false,
          calledCardTool: true,
          cardArgumentsRender: true,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.unsupported,
      );
    });

    // The "won't" counterpart to the unsupported ("can't") case above: the
    // model proved it can call tools at all via the trivial one, but never
    // reaches for the card tool specifically.
    test('a capable model that never reaches for the card tool declines', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: false,
          cardArgumentsRender: false,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.supportedButDeclines,
      );
    });

    // Exercises the negative-control failure: the file doc comment notes
    // the seed data already showed 5 of 15 models over-call the card tool
    // on a plain prose question, so this is a measured risk, not a
    // hypothetical edge case.
    test('calling the card tool on a prose question is over-calling', () {
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: true,
          calledOnNegativeControl: true,
        ),
        ToolVerdict.overCalls,
      );
    });

    test('over-calling outranks unrenderable arguments', () {
      // Both are faults; over-calling is the one that changes what a user
      // sees on every prose question, so it is the verdict worth surfacing.
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: false,
          calledOnNegativeControl: true,
        ),
        ToolVerdict.overCalls,
      );
    });

    test('a card tool call whose arguments do not render is a decline', () {
      // It reached for the tool but produced nothing renderable, which is
      // not "supported" — supported means the channel actually works.
      expect(
        classifyToolSupport(
          calledTrivialTool: true,
          calledCardTool: true,
          cardArgumentsRender: false,
          calledOnNegativeControl: false,
        ),
        ToolVerdict.supportedButDeclines,
      );
    });

    test('unsupported outranks over-calling', () {
      // A template with no tool support cannot have meaningfully over-called
      // anything, so the discriminator wins over every other signal.
      expect(
        classifyToolSupport(
          calledTrivialTool: false,
          calledCardTool: true,
          cardArgumentsRender: true,
          calledOnNegativeControl: true,
        ),
        ToolVerdict.unsupported,
      );
    });
  });
}
