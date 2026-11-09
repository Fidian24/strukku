import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// Dekorasi input seragam (sudut membulat, border tipis, label kecil).
InputDecoration strukkuDecoration({
  String? label,
  String? hint,
  String? prefixText,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
    hintStyle: const TextStyle(color: Color(0xFFA3AEC0)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.primary, 1.6),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.6),
  );
}

/// Kolom input teks. Untuk password, ikon mata ditampilkan otomatis.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.prefixText,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      autocorrect: !widget.isPassword,
      enableSuggestions: !widget.isPassword,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.navy),
      decoration: strukkuDecoration(
        label: widget.label,
        hint: widget.hint,
        prefixText: widget.prefixText,
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textGrey,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
      ),
    );
  }
}
