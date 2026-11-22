import 'dart:async';

import 'package:auth_notification_app/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:auth_notification_app/features/auth/presentation/manager/auth_cubit/auth_state.dart';
import 'package:auth_notification_app/features/notifications/domain/entities/approval_request.dart';
import 'package:auth_notification_app/features/notifications/presentation/manager/approval_coordinator/approval_cubit.dart';
import 'package:auth_notification_app/features/notifications/presentation/manager/approval_request_coordinator.dart';
import 'package:auth_notification_app/features/notifications/presentation/manager/pending_approval_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

class MockApprovalCubit extends Mock implements ApprovalCubit {}

void main() {
  late MockAuthCubit authCubit;
  late MockApprovalCubit approvalCubit;
  late PendingApprovalManager pendingApprovalManager;
  late StreamController<AuthState> authController;
  late ApprovalRequestCoordinator coordinator;

  late AuthState currentAuthState;
  late List<ApprovalRequest> readyRequests;

  setUp(() {
    authCubit = MockAuthCubit();
    approvalCubit = MockApprovalCubit();

    pendingApprovalManager = PendingApprovalManager();
    authController = StreamController<AuthState>.broadcast(sync: true);

    currentAuthState = const AuthUnauthenticated();
    readyRequests = [];

    when(() => authCubit.state).thenAnswer((_) => currentAuthState);

    when(() => authCubit.stream).thenAnswer((_) => authController.stream);

    coordinator = ApprovalRequestCoordinator(
      authCubit: authCubit,
      approvalCubit: approvalCubit,
      pendingApprovalManager: pendingApprovalManager,
      onRequestReady: readyRequests.add,
    );
  });

  tearDown(() async {
    await coordinator.dispose();
    await authController.close();
  });

  group('ApprovalRequestCoordinator', () {
    test('stores deep link without fetching when user is unauthenticated', () {
      final accepted = coordinator.handleLink(
        Uri.parse('myapp://approval/request_001'),
      );

      expect(accepted, isTrue);
      expect(pendingApprovalManager.pendingRequestId, 'request_001');
      expect(readyRequests, isEmpty);

      verifyNever(
        () => approvalCubit.fetchRequest(requestId: any(named: 'requestId')),
      );
    });

    test('fetches pending request when user becomes authenticated', () async {
      const request = ApprovalRequest(
        requestId: 'request_001',
        title: 'New Shop Approval',
        description: 'A new shop is waiting for your approval.',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) async => request);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [request]);
      expect(pendingApprovalManager.hasPendingRequest, isFalse);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test('does not fetch the same request twice while processing', () async {
      final completer = Completer<ApprovalRequest?>();

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) => completer.future);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      completer.complete(
        const ApprovalRequest(
          requestId: 'request_001',
          title: 'New Shop Approval',
          description: 'A new shop is waiting for your approval.',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests.length, 1);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test('does not process an already handled request again', () async {
      const request = ApprovalRequest(
        requestId: 'request_001',
        title: 'New Shop Approval',
        description: 'A new shop is waiting for your approval.',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) async => request);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, [request]);
      expect(pendingApprovalManager.hasPendingRequest, isFalse);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test(
      'processes the latest request when a new link arrives during fetch',
      () async {
        final firstCompleter = Completer<ApprovalRequest?>();
        final secondCompleter = Completer<ApprovalRequest?>();

        const firstRequest = ApprovalRequest(
          requestId: 'request_001',
          title: 'First Request',
          description: 'First description',
        );

        const secondRequest = ApprovalRequest(
          requestId: 'request_002',
          title: 'Second Request',
          description: 'Second description',
        );

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).thenAnswer((_) => firstCompleter.future);

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_002'),
        ).thenAnswer((_) => secondCompleter.future);

        coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        await Future<void>.delayed(Duration.zero);

        coordinator.handleLink(Uri.parse('myapp://approval/request_002'));

        firstCompleter.complete(firstRequest);

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, isEmpty);

        secondCompleter.complete(secondRequest);

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, [secondRequest]);
        expect(pendingApprovalManager.hasPendingRequest, isFalse);

        verify(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).called(1);

        verify(
          () => approvalCubit.fetchRequest(requestId: 'request_002'),
        ).called(1);
      },
    );

    test('keeps pending request when fetching fails', () async {
      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) async => null);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, isEmpty);
      expect(pendingApprovalManager.pendingRequestId, 'request_001');
      expect(pendingApprovalManager.hasPendingRequest, isTrue);

      verify(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).called(1);
    });

    test('does not deliver request when user logs out during fetch', () async {
      final completer = Completer<ApprovalRequest?>();

      const request = ApprovalRequest(
        requestId: 'request_001',
        title: 'New Shop Approval',
        description: 'A new shop is waiting for your approval.',
      );

      when(
        () => approvalCubit.fetchRequest(requestId: 'request_001'),
      ).thenAnswer((_) => completer.future);

      coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

      currentAuthState = const AuthAuthenticated();
      authController.add(currentAuthState);

      await Future<void>.delayed(Duration.zero);

      currentAuthState = const AuthUnauthenticated();
      authController.add(currentAuthState);

      completer.complete(request);

      await Future<void>.delayed(Duration.zero);

      expect(readyRequests, isEmpty);
      expect(pendingApprovalManager.pendingRequestId, 'request_001');

      verify(() => approvalCubit.reset()).called(1);
    });

    test(
      'retries pending request when user logs in again during fetch',
      () async {
        final firstCompleter = Completer<ApprovalRequest?>();
        final secondCompleter = Completer<ApprovalRequest?>();

        const request = ApprovalRequest(
          requestId: 'request_001',
          title: 'New Shop Approval',
          description: 'A new shop is waiting for your approval.',
        );

        var fetchCount = 0;

        when(
          () => approvalCubit.fetchRequest(requestId: 'request_001'),
        ).thenAnswer((_) {
          fetchCount++;

          if (fetchCount == 1) {
            return firstCompleter.future;
          }

          return secondCompleter.future;
        });

        coordinator.handleLink(Uri.parse('myapp://approval/request_001'));

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        await Future<void>.delayed(Duration.zero);

        currentAuthState = const AuthUnauthenticated();
        authController.add(currentAuthState);

        currentAuthState = const AuthAuthenticated();
        authController.add(currentAuthState);

        firstCompleter.complete(request);

        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(fetchCount, 2);
        expect(readyRequests, isEmpty);

        secondCompleter.complete(request);

        await Future<void>.delayed(Duration.zero);

        expect(readyRequests, [request]);
        expect(pendingApprovalManager.hasPendingRequest, isFalse);
      },
    );

    test('rejects invalid deep links', () {
      final accepted = coordinator.handleLink(
        Uri.parse('https://example.com/request_001'),
      );

      expect(accepted, isFalse);
      expect(pendingApprovalManager.hasPendingRequest, isFalse);

      verifyNever(
        () => approvalCubit.fetchRequest(requestId: any(named: 'requestId')),
      );
    });
  });
}
