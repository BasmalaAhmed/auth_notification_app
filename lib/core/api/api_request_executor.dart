import 'package:auth_notification_app/core/errors/api_exception.dart';
import 'package:auth_notification_app/core/session/session_manager.dart';

class ApiRequestExecutor {
  final SessionManager sessionManager;

  ApiRequestExecutor(this.sessionManager);

  Future<T> execute<T>({
    required Future<T> Function(String accessToken) request,
  }) async {
    final session = sessionManager.currentSession;

    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active session.',
      );
    }

    try {
      return await request(session.accessToken);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;

      final refreshedSession = await sessionManager.refreshSession();

      return request(refreshedSession.accessToken);
    }
  }
}