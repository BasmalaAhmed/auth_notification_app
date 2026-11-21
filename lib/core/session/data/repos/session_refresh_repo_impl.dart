import 'package:auth_notification_app/core/session/data/datasources/mock_session_api.dart';
import 'package:auth_notification_app/core/session/entities/session.dart';
import 'package:auth_notification_app/core/session/repos/session_refresh_repo.dart';

class SessionRefreshRepoImpl
    implements SessionRefreshRepo {
  final MockSessionApi mockSessionApi;

  SessionRefreshRepoImpl(this.mockSessionApi);

  @override
  Future<Session> refreshSession({
    required String refreshToken,
  }) async {
    final response = await mockSessionApi.refreshToken(
      refreshToken: refreshToken,
    );

    return Session(
      accessToken: response['access_token'] as String,
      refreshToken: response['refresh_token'] as String,
      expiresAt: DateTime.parse(
        response['expires_at'] as String,
      ),
    );
  }
}