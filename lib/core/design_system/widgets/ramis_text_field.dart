import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RamisTextField extends StatelessWidget {
  const RamisTextField({
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
    this.focusNode,
    this.autofocus = false,
    this.maxLength,
    this.decoration,
    this.initialValue,
    this.onSaved,
    this.onTap,
    this.readOnly = false,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.autovalidateMode,
    this.autocorrect = true,
    this.enableSuggestions = true,
    super.key,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? minLines;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxLength;
  final InputDecoration? decoration;
  final String? initialValue;
  final FormFieldSetter<String>? onSaved;
  final VoidCallback? onTap;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      onSaved: onSaved,
      onTap: onTap,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      autofillHints: autofillHints,
      focusNode: focusNode,
      autofocus: autofocus,
      maxLength: maxLength,
      decoration: decoration ??
          InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
    );
  }
}
