import 'package:test/test.dart';

// Relative: the probe lives outside lib/, so there is no package: URI.
import '../tool/model_probes/tool_call_probe.dart';

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
  });
}
