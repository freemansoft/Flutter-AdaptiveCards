import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/src/models/invoke_kind.dart';

/// Backend-neutral envelope built from library invoke callbacks.
///
/// Serialize with `PlainJsonInvokeAdapter` or `TeamsInvokeAdapter` before POST.
class AdaptiveCardInvokeRequest {
  /// Low-level invoke envelope; prefer `fromSubmit`, `fromExecute`, and other
  /// factories built from card callback payloads.
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

  /// Maps Submit callback data for backend POST
  /// via `AdaptiveCardBackendHandlers`.
  factory AdaptiveCardInvokeRequest.fromSubmit(SubmitActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.submit,
      actionId: invoke.actionId,
      data: invoke.data,
    );
  }

  /// Maps Execute/Refresh callback data for backend POST.
  factory AdaptiveCardInvokeRequest.fromExecute(ExecuteActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.execute,
      actionId: invoke.actionId,
      verb: invoke.verb,
      data: invoke.data,
    );
  }

  /// Maps dynamic ChoiceSet input-change callbacks (includes [DataQuery] when
  /// present on the input).
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

  /// Open-url payload when forwarding [OpenUrlActionInvoke] to a backend.
  factory AdaptiveCardInvokeRequest.fromOpenUrl(OpenUrlActionInvoke invoke) {
    return AdaptiveCardInvokeRequest(
      kind: AdaptiveCardInvokeKind.openUrl,
      actionId: invoke.actionId,
      url: invoke.url,
    );
  }

  /// Teams [OpenUrlDialogActionInvoke] payload when forwarding to a backend.
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
