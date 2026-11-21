import 'package:auth_notification_app/features/auth/domain/entities/auth_results.dart';
import 'package:auth_notification_app/features/auth/domain/repos/auth_repo.dart';

class VerifyOtpUseCase {
  final AuthRepo repo;

  const VerifyOtpUseCase(this.repo);

  Future<AuthResult> call({required String challengeId, required String code}) {
    return repo.verifyOtp(challengeId: challengeId, code: code);
  }
}
