import 'package:auth_notification_app/core/session/session_manager.dart';
import 'package:auth_notification_app/features/auth/presentation/views/device_verification_view.dart';
import 'package:auth_notification_app/features/auth/presentation/views/home_view.dart';
import 'package:auth_notification_app/features/auth/presentation/views/login_view.dart';
import 'package:auth_notification_app/features/auth/presentation/views/otp_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/app_dependencies.dart';
import 'features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'features/auth/presentation/manager/auth_cubit/auth_state.dart';

class AuthNotificationApp extends StatelessWidget {
  final AppDependencies dependencies;

  const AuthNotificationApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => dependencies.createAuthCubit()..restoreSession(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Auth Notification App',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D9488)),
        ),
        home: AuthGate(sessionManager: dependencies.sessionManager),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final SessionManager sessionManager;

  const AuthGate({super.key, required this.sessionManager});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthState _lastStableState = const AuthInitial();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is! AuthLoading && state is! AuthInitial) {
          _lastStableState = state;
        }
      },
      builder: (context, state) {
        final currentState = state is AuthLoading ? _lastStableState : state;

        if (currentState is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (currentState is AuthUnauthenticated ||
            currentState is AuthFailure) {
          return const LoginView();
        }

        if (currentState is AuthOtpRequired) {
          return OtpView(challenge: currentState.challenge);
        }

        if (currentState is AuthDeviceVerificationRequired) {
          return DeviceVerificationView(challenge: currentState.challenge);
        }

        if (currentState is AuthAuthenticated) {
          return HomeView(sessionManager: widget.sessionManager);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
