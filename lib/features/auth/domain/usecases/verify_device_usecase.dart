import 'package:auth_notification_app/features/auth/domain/entities/auth_result.dart';
import 'package:auth_notification_app/features/auth/domain/repos/auth_repo.dart';

class VerifyDeviceUseCase {
  final AuthRepo repo;

  const VerifyDeviceUseCase(this.repo);

  Future<AuthResult> call({required String challengeId, required String code}) {
    return repo.verifyDevice(challengeId: challengeId, code: code);
  }
}
