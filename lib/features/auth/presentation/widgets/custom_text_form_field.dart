import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.isLoading,
    this.isPassword = false,
    required this.onSubmitted,
    required this.onPressed,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isPassword;
  final VoidCallback onSubmitted, onPressed;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: !isLoading,
      obscureText: isPassword,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) => isLoading ? null : onSubmitted,
      decoration:
          _inputDecoration(
            hint: isPassword ? 'Enter your password' : 'Enter your email',
            icon: isPassword ? Icons.lock_outline_rounded : Icons.email_outlined,
          ).copyWith(
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: isLoading ? null : onPressed,
                    icon: Icon(
                      isPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                    ),
                  )
                : null,
          ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isPassword
              ? 'Please enter your password.'
              : 'Please enter your email.';
        }

        if (isPassword) {
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
            return 'Please enter a valid email.';
          }
        }

        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BAC7), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
