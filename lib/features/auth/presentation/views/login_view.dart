import 'package:auth_notification_app/features/auth/presentation/widgets/custom_text_form_field.dart';
import 'package:auth_notification_app/features/auth/presentation/widgets/error_message.dart';
import 'package:auth_notification_app/features/auth/presentation/widgets/header.dart';
import 'package:auth_notification_app/features/auth/presentation/widgets/login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:auth_notification_app/features/auth/domain/entities/login_credentials.dart';
import 'package:auth_notification_app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:auth_notification_app/features/auth/presentation/manager/auth_cubit/auth_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  static const Color primaryColor = Color(0xFF1E293B);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    context.read<AuthCubit>().login(
      LoginCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Header(),

                      const SizedBox(height: 36),

                      _buildLoginCard(isLoading: isLoading, state: state),

                      const SizedBox(height: 28),

                      const Text(
                        'Secure authentication for your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard({required bool isLoading, required AuthState state}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter your credentials below.',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),

            const SizedBox(height: 28),
            Text(
              'Email Address',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 10),

            CustomTextFormField(
              controller: _emailController,
              isLoading: isLoading,
              onSubmitted: () {},
              onPressed: () {},
            ),

            const SizedBox(height: 22),

            Text(
              'Password',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 10),

            CustomTextFormField(
              controller: _passwordController,
              isLoading: isLoading,
              isPassword: true,
              onSubmitted: _login,
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),

            if (state is AuthFailure) ...[
              const SizedBox(height: 16),

              ErrorMessage(message: state.message),
            ],

            const SizedBox(height: 28),

            LoginButton(isLoading: isLoading, onPressed: _login),
          ],
        ),
      ),
    );
  }
}
