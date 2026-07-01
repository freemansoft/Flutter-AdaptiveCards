import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/input_text_validation.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Input.Text.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/input-text
///
class AdaptiveTextInput extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a text input from [adaptiveMap] JSON.
  AdaptiveTextInput({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveTextInputState createState() => AdaptiveTextInputState();
}

/// State for [AdaptiveTextInput]; handles single- and multi-line text entry.
class AdaptiveTextInputState extends ConsumerState<AdaptiveTextInput>
    with
        AdaptiveTextualInputMixin,
        AdaptiveInputMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  /// Text field holding the current input value.
  TextEditingController controller = TextEditingController();
  late FocusNode _focusNode;
  bool _controllerListenerInstalled = false;
  bool _isUpdatingFromDocument = false;
  bool _initialValueSynced = false;

  /// Whether password characters are currently hidden (`style: password`).
  ///
  /// Flipped via `setState` when the reveal (eye-icon) toggle is tapped.
  bool _obscure = true;

  /// Maximum character count from `maxLength`, or `null` when absent.
  ///
  /// Per the Adaptive Cards spec, `maxLength` is optional. A `null` value (or
  /// a value ≤ 0) means no limit is applied. The formatter is only installed
  /// when this is a positive integer.
  int? maxLength;

  /// Keyboard type derived from `style` (`tel`, `url`, `email`, etc.).
  TextInputType? inputStyle;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus || _isUpdatingFromDocument) {
      return;
    }
    notifyUserInputValueChanged(controller.text, committed: true);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    controller.dispose();
    super.dispose();
  }

  /// Whether the field expands for multiple lines (`isMultiline`).
  late bool isMultiline;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isMultiline = adaptiveMap['isMultiline'] as bool? ?? false;
    maxLength = adaptiveMap['maxLength'] as int?;
    inputStyle = resolveTextInputType(style);

    if (!_initialValueSynced) {
      _initialValueSynced = true;
      onDocumentValueChanged(readResolvedInput().valueRaw);
    }

    if (!_controllerListenerInstalled) {
      _controllerListenerInstalled = true;
      controller.addListener(() {
        if (_isUpdatingFromDocument) return;
        final text = controller.text;
        setDocumentInputValue(text);
        rawRootCardWidgetState.changeValue(id, text);
      });
    }
  }

  @override
  void onDocumentValueChanged(Object? valueFromDocument) {
    final next = valueFromDocument?.toString() ?? '';
    if (controller.text == next) return;
    _isUpdatingFromDocument = true;
    controller.text = next;
    _isUpdatingFromDocument = false;
  }

  @override
  Widget build(BuildContext context) {
    listenForResolvedValueChanges();
    final input = watchResolvedInput();
    final isPassword = input.style == 'password';
    // Fall back to the fallback InputsConfig when the host provides none
    // (matches the resolver fallback pattern, e.g. getFontSizesConfig).
    final inputsConfig =
        styleResolver.getInputsConfig() ?? FallbackConfigs.inputsConfig;
    final revealEnabled =
        input.revealPasswordEnabledOverride ??
        inputsConfig.text.revealPasswordEnabled;
    // Capture into a local so Dart flow analysis can promote the nullable
    // field.
    final effectiveMaxLength = maxLength;

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            loadLabel(
              context: context,
              label: input.label,
              isRequired: input.isRequired,
            ),
            SizedBox(
              height: 40,
              child: TextFormField(
                key: generateWidgetKey(adaptiveMap),
                focusNode: _focusNode,
                style: const TextStyle(),
                controller: controller,
                // maxLength: maxLength,
                inputFormatters: [
                  if (effectiveMaxLength != null && effectiveMaxLength > 0)
                    LengthLimitingTextInputFormatter(effectiveMaxLength),
                ],
                keyboardType: inputStyle,
                obscureText: isPassword && _obscure,
                enableSuggestions: !isPassword,
                autocorrect: !isPassword,
                maxLines: (isMultiline && !isPassword) ? null : 1,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(width: 1),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(width: 1),
                  ),
                  filled: true,
                  fillColor: styleResolver.resolveInputBackgroundColor(
                    context: context,
                    style: null,
                  ),
                  hintText: input.placeholder,
                  // required or box will exist even though field is hidden or
                  // half height
                  hintStyle: const TextStyle(),
                  suffixIcon: (isPassword && revealEnabled)
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          constraints: const BoxConstraints(
                            maxHeight: 36,
                            maxWidth: 36,
                          ),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          // Library has no l10n/arb setup (intl is date-only),
                          // so these accessibility labels are plain strings,
                          // consistent with the rest of the package.
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    maxHeight: 36,
                    maxWidth: 36,
                  ),
                  errorStyle: const TextStyle(height: 0),
                ),
                validator: (value) {
                  final regexPattern = adaptiveMap['regex'] as String?;
                  if (!textInputValueIsValid(
                    value: value,
                    isRequired: input.isRequired,
                    regexPattern: regexPattern,
                  )) {
                    setLocalValidationError();
                    return '';
                  }
                  clearLocalValidationError();
                  return null;
                },
                onEditingComplete: () {
                  notifyUserInputValueChanged(controller.text, committed: true);
                },
              ),
            ),
            loadErrorMessage(
              context: context,
              errorMessage: input.errorMessage,
              showError: input.isInvalid,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void appendInput(Map map) {
    map[id] = controller.text;
  }

  @override
  void initInput(Map map) {
    if (map[id] != null) {
      setDocumentInputValue(map[id]);
    }
  }

  @override
  bool checkRequired() {
    final adaptiveCardElement = adaptiveCardElementState;
    final formKey = adaptiveCardElement.formKey;

    return formKey.currentState!.validate();
  }

  /// JSON Schema definition "TextInputStyle"
  TextInputType? resolveTextInputType(String? style) {
    /// Can be one of the following:
    /// - 'text'
    /// - 'tel'
    /// - 'url'
    /// - 'email'
    final String myStyle = (style != null) ? style.toLowerCase() : 'text';
    switch (myStyle) {
      case 'text':
        return TextInputType.text;
      case 'tel':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'email':
        return TextInputType.emailAddress;
      case 'password':
        return TextInputType.visiblePassword;
      default:
        return null;
    }
  }
}
