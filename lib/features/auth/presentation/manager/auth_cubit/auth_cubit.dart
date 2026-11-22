import 'package:auth_notification_app/features/auth/domain/entities/device_verification_challenge.dart';
import 'package:auth_notification_app/features/auth/domain/entities/otp_challenge.dart';
import 'package:auth_notification_app/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auth_notification_app/core/session/session_manager.dart';
import 'package:auth_notification_app/features/auth/domain/entities/auth_result.dart';
import 'package:auth_notification_app/features/auth/domain/entities/login_credentials.dart';
import 'package:auth_notification_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:auth_notification_app/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:auth_notification_app/features/auth/domain/usecases/verify_device_usecase.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final VerifyDeviceUseCase verifyDeviceUseCase;
  final SessionManager sessionManager;
  OtpChallenge? _otpChallenge;
  DeviceVerificationChallenge? _deviceChallenge;
  bool _isProcessing = false;

  AuthCubit({
    required this.loginUseCase,
    required this.verifyOtpUseCase,
    required this.verifyDeviceUseCase,
    required this.sessionManager,
  }) : super(const AuthInitial());

  Future<void> restoreSession() async {
    if (_isProcessing) return;

    _isProcessing = true;

    emit(const AuthLoading());

    try {
      final session = sessionManager.currentSession;

      if (session == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      if (session.isExpired) {
        await sessionManager.refreshSession();
      }

      if (isClosed) return;

      emit(const AuthAuthenticated());
    } catch (_) {
      if (!isClosed) {
        emit(const AuthUnauthenticated());
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> login(LoginCredentials credentials) async {
    if (_isProcessing) return;

    _isProcessing = true;

    _otpChallenge = null;
    _deviceChallenge = null;

    emit(const AuthLoading());

    try {
      final challenge = await loginUseCase(credentials);
      if (isClosed) return;
      _otpChallenge = challenge;
      emit(AuthOtpRequired(challenge));
    } catch (_) {
      if (!isClosed) {
        emit(const AuthFailure('Login failed.'));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> verifyOtp(String code) async {
    if (_isProcessing) return;

    final challenge = _otpChallenge;

    if (challenge == null) {
      emit(const AuthFailure('OTP challenge not found.'));
      return;
    }

    _isProcessing = true;

    emit(const AuthLoading());

    try {
      AuthResult result;

      try {
        result = await verifyOtpUseCase(
          challengeId: challenge.challengeId,
          code: code,
        );
      } catch (_) {
        if (!isClosed) {
          emit(
            AuthOtpRequired(
              challenge,
              errorMessage: 'OTP verification failed.',
            ),
          );
        }
        return;
      }

      if (isClosed) return;

      if (result is DeviceVerificationRequired) {
        _deviceChallenge = result.challenge;
        _otpChallenge = null;

        emit(AuthDeviceVerificationRequired(result.challenge));
      } else if (result is AuthSuccess) {
        try {
          await _completeAuthentication(result);
        } catch (_) {
          if (!isClosed) {
            emit(const AuthFailure('Failed to save session.'));
          }
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> verifyDevice(String code) async {
    if (_isProcessing) return;

    final challenge = _deviceChallenge;

    if (challenge == null) {
      emit(const AuthFailure('Device challenge not found.'));
      return;
    }

    _isProcessing = true;

    emit(const AuthLoading());

    try {
      AuthResult result;

      try {
        result = await verifyDeviceUseCase(
          challengeId: challenge.challengeId,
          code: code,
        );
      } catch (_) {
        if (!isClosed) {
          emit(
            AuthDeviceVerificationRequired(
              challenge,
              errorMessage: 'Device verification failed.',
            ),
          );
        }
        return;
      }

      if (isClosed) return;

      if (result is AuthSuccess) {
        try {
          await _completeAuthentication(result);
        } catch (_) {
          if (!isClosed) {
            emit(const AuthFailure('Failed to save session.'));
          }
        }
      } else if (result is DeviceVerificationRequired) {
        _deviceChallenge = result.challenge;

        emit(AuthDeviceVerificationRequired(result.challenge));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _completeAuthentication(AuthSuccess result) async {
    await sessionManager.setSession(result.session);

    if (isClosed) return;

    _otpChallenge = null;
    _deviceChallenge = null;

    emit(const AuthAuthenticated());
  }

  Future<void> logout() async {
    if (_isProcessing) return;

    _isProcessing = true;
    emit(const AuthLoading());

    try {
      await sessionManager.logout();

      _otpChallenge = null;
      _deviceChallenge = null;

      if (!isClosed) {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      if (!isClosed) {
        emit(const AuthFailure('Logout failed. Please try again.'));
      }
    } finally {
      _isProcessing = false;
    }
  }
}
