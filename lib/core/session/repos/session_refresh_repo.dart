import 'package:auth_notification_app/core/session/entities/session.dart';

abstract class SessionRefreshRepo {
  Future<Session> refreshSession({
    required String refreshToken,
  });
}