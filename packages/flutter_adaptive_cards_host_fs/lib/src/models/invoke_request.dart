import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_kind.dart';

/// Backend-neutral envelope built from library invoke callbacks.
///
/// Serialize with `PlainJsonInvokeAdapter` or `TeamsInvokeAdapter` before POST.
class AdaptiveCardInvokeRequest {
  /// Creates an invoke request with the given [kind] and optional fields.
  const AdaptiveCardInvokeRequest({
    required this.kind,
    this.actionId,
    this.verb,
    this.data = const {},
    this.inputId,
    this.value,
    this.dataQuery,
    this.url,
  });

  /// Builds a request from [SubmitActionInvoke].
  factory AdaptiveCardInvokeRequest.fromSubmit(SubmitActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.submit,
      actionId: invoke.actionId,
      data: invoke.data,
    );
  }

  /// Builds a request from [ExecuteActionInvoke].
  factory AdaptiveCardInvokeRequest.fromExecute(ExecuteActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.execute,
      actionId: invoke.actionId,
      verb: invoke.verb,
      data: invoke.data,
    );
  }

  /// Builds a request from [InputChangeInvoke].
  ///
  /// [data] is populated from [DataQuery.parameters] when present.
  factory AdaptiveCardInvokeRequest.fromInputChange(InputChangeInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.inputChange,
      inputId: invoke.inputId,
      value: invoke.value,
      dataQuery: invoke.dataQuery,
      data: invoke.dataQuery?.parameters ?? const {},
    );
  }

  /// Builds a request from [OpenUrlActionInvoke].
  factory AdaptiveCardInvokeRequest.fromOpenUrl(OpenUrlActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.openUrl,
      actionId: invoke.actionId,
      url: invoke.url,
    );
  }

  /// Builds a request from [OpenUrlDialogActionInvoke].
  factory AdaptiveCardInvokeRequest.fromOpenUrlDialog(
    OpenUrlDialogActionInvoke invoke,
  ) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.openUrlDialog,
      actionId: invoke.actionId,
      url: invoke.url,
    );
  }

  /// Callback category being forwarded to the backend.
  final AdaptiveCardInvokeKind kind;

  /// Author-defined action `id` from card JSON, when applicable.
  final String? actionId;

  /// `Action.Execute` verb from card JSON, when applicable.
  final String? verb;

  /// Merged action `data` and/or sibling input values for invoke payloads.
  final Map<String, dynamic> data;

  /// Changed input `id` for [AdaptiveCardInvokeKind.inputChange].
  final String? inputId;

  /// New input value for [AdaptiveCardInvokeKind.inputChange].
  final Object? value;

  /// Parsed `choices.data` for dynamic ChoiceSet invokes.
  final DataQuery? dataQuery;

  /// Target URL for open-url invoke kinds.
  final String? url;
}
