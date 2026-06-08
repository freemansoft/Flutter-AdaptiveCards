/// Kind of host callback serialized for a backend invoke request.
enum AdaptiveCardInvokeKind {
  /// `Action.Submit` or equivalent submit payload.
  submit,

  /// `Action.Execute` with optional `verb`.
  execute,

  /// Input value change, often with `Data.Query` for dynamic search.
  inputChange,

  /// `Action.OpenUrl`.
  openUrl,

  /// `Action.OpenUrlDialog` (Teams extension).
  openUrlDialog,
}
