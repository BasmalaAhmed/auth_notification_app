import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:auth_notification_app/core/api/api_request_executor.dart';
import 'package:auth_notification_app/core/errors/api_exception.dart';
import 'package:auth_notification_app/core/session/entities/session.dart';
import 'package:auth_notification_app/core/session/repos/session_refresh_repo.dart';
import 'package:auth_notification_app/core/session/repos/session_repo.dart';
import 'package:auth_notification_app/core/session/session_manager.dart';

class MockSessionRepo extends Mock implements SessionRepo {}

class MockSessionRefreshRepo extends Mock implements SessionRefreshRepo {}

void main() {
  late MockSessionRepo mockSessionRepo;
  late MockSessionRefreshRepo mockRefreshRepo;
  late SessionManager sessionManager;
  late ApiRequestExecutor executor;

  final initialSession = Session(
    accessToken: 'old_access',
    refreshToken: 'old_refresh',
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
  );

  final refreshedSession = Session(
    accessToken: 'new_access',
    refreshToken: 'new_refresh',
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
  );

  setUp(() async {
    mockSessionRepo = MockSessionRepo();
    mockRefreshRepo = MockSessionRefreshRepo();

    sessionManager = SessionManager(
      mockSessionRepo,
      mockRefreshRepo,
    );

    executor = ApiRequestExecutor(sessionManager);

    when(
      () => mockSessionRepo.getSession(),
    ).thenAnswer((_) async => initialSession);

    await sessionManager.initialize();
  });

  test('executes request without refreshing when successful', () async {
    final result = await executor.execute<String>(
      request: (accessToken) async {
        expect(accessToken, 'old_access');
        return 'success';
      },
    );

    expect(result, 'success');

    verifyNever(
      () => mockRefreshRepo.refreshSession(
        refreshToken: any(named: 'refreshToken'),
      ),
    );
  });

  test('refreshes token once after 401 and retries request', () async {
    var attempts = 0;

    when(
      () => mockRefreshRepo.refreshSession(
        refreshToken: 'old_refresh',
      ),
    ).thenAnswer((_) async => refreshedSession);

    when(
      () => mockSessionRepo.saveSession(refreshedSession),
    ).thenAnswer((_) async {});

    final result = await executor.execute<String>(
      request: (accessToken) async {
        attempts++;

        if (attempts == 1) {
          expect(accessToken, 'old_access');

          throw const ApiException(
            statusCode: 401,
            message: 'Unauthorized',
          );
        }

        expect(accessToken, 'new_access');

        return 'success';
      },
    );

    expect(result, 'success');
    expect(attempts, 2);
    expect(sessionManager.currentSession, refreshedSession);

    verify(
      () => mockRefreshRepo.refreshSession(
        refreshToken: 'old_refresh',
      ),
    ).called(1);
  });

  test('does not refresh token when server returns 403', () async {
    await expectLater(
      executor.execute<String>(
        request: (_) async {
          throw const ApiException(
            statusCode: 403,
            message: 'Forbidden',
          );
        },
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          403,
        ),
      ),
    );

    verifyNever(
      () => mockRefreshRepo.refreshSession(
        refreshToken: any(named: 'refreshToken'),
      ),
    );
  });

  test('does not refresh again when retry also returns 401', () async {
    var attempts = 0;

    when(
      () => mockRefreshRepo.refreshSession(
        refreshToken: 'old_refresh',
      ),
    ).thenAnswer((_) async => refreshedSession);

    when(
      () => mockSessionRepo.saveSession(refreshedSession),
    ).thenAnswer((_) async {});

    await expectLater(
      executor.execute<String>(
        request: (_) async {
          attempts++;

          throw const ApiException(
            statusCode: 401,
            message: 'Unauthorized',
          );
        },
      ),
      throwsA(isA<ApiException>()),
    );

    expect(attempts, 2);

    verify(
      () => mockRefreshRepo.refreshSession(
        refreshToken: 'old_refresh',
      ),
    ).called(1);
  });
}