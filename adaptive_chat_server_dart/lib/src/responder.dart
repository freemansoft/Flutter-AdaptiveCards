/// Reply strategies and the value type they return.
library;

import 'package:adaptive_chat_server_dart/src/stats.dart';

/// A responder's answer: raw text (for history) plus an optional card body.
///
/// [text] is always the model's raw output and is what threads into Ollama
/// conversation history. [cardBody] holds the parsed Adaptive Card body
/// items when the reply is *only* a card (rendered inside the assistant
/// bubble); `null` means render [text] as a Markdown text bubble.
///
/// [stats] carries the responder's token/timing usage for this turn, or
/// `null` when the reply cost nothing measurable (echo mode, or any failure
/// path). It never affects what the user sees — it exists for `GET /status`.
class Reply {
  /// Creates a [Reply] with the given text, optional card body, and stats.
  const Reply({
    required this.text,
    this.cardBody,
    this.stats,
    this.ok = true,
  });

  /// The responder's raw text output for conversation history.
  final String text;

  /// Whether this reply is the model's actual answer.
  ///
  /// `false` marks a diagnostic stand-in produced when the responder could
  /// not reach or understand the model. Such a [text] is shown to the user
  /// but must never be replayed as conversation history — the model would
  /// read its own error message as something it once said.
  final bool ok;

  /// Optional parsed Adaptive Card body items, or null to render text as
  /// Markdown.
  final List<Map<String, dynamic>>? cardBody;

  /// Optional token/timing usage for this reply.
  final InteractionStats? stats;
}

/// Whether a responder can actually serve requests, and why not if it can't.
///
/// Exists so a misconfiguration surfaces at startup, where the operator is
/// looking, rather than as an error bubble on the first user message.
class ResponderReadiness {
  /// The responder is able to serve requests.
  const ResponderReadiness.ready(this.detail) : isReady = true;

  /// The responder cannot serve requests; [detail] says what to fix.
  const ResponderReadiness.notReady(this.detail) : isReady = false;

  /// Whether the responder is able to serve requests right now.
  final bool isReady;

  /// Operator-facing explanation — the remedy when not ready.
  final String detail;
}

/// Turns a user message (plus prior turns) into a [Reply].
abstract interface class Responder {
  /// Generates a reply based on user text and conversation history.
  ///
  /// Returns a [Reply] with the responder's answer and optional metadata.
  Future<Reply> reply(String text, List<(String, String)> history);

  /// Effective configuration of this responder, for `GET /status`.
  ///
  /// Reports what the process is *actually* running, not what it was asked
  /// for — a responder may resolve or downgrade its own settings at
  /// construction, and it is the only component that knows the difference.
  /// Keys are camelCase because the result is served verbatim as JSON.
  Map<String, dynamic> describe();

  /// Probes whatever this responder depends on, for a startup report.
  ///
  /// Never throws and never blocks startup: a responder that cannot answer
  /// yet may still recover (an Ollama started after the server), so the
  /// result is advisory and the caller decides how loudly to say so.
  Future<ResponderReadiness> checkReadiness();
}

/// v1 responder: echoes the user's text back. Ignores history; never a card.
class EchoResponder implements Responder {
  @override
  Future<Reply> reply(String text, List<(String, String)> history) async =>
      Reply(text: 'Did you just say: $text');

  @override
  Map<String, dynamic> describe() => {'kind': 'echo'};

  /// Always ready — it depends on nothing outside this process.
  @override
  Future<ResponderReadiness> checkReadiness() async =>
      const ResponderReadiness.ready('echo responder needs no backend');
}
