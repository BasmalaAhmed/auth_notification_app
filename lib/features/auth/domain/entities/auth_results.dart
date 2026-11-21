import 'device_verification_challenge.dart';

sealed class AuthResult {
  const AuthResult();
}

class DeviceVerificationRequired extends AuthResult {
  final DeviceVerificationChallenge challenge;

  const DeviceVerificationRequired({
    required this.challenge,
  });
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}