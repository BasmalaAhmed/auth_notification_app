import 'package:auth_notification_app/core/session/entities/session.dart';

abstract class SessionRepo {
  Future<void> saveSession(Session session);

  Future<Session?> getSession();

  Future<void> clearSession();
}