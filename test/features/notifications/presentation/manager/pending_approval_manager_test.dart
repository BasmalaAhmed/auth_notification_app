import 'package:flutter_test/flutter_test.dart';
import 'package:auth_notification_app/features/notifications/presentation/manager/pending_approval_manager.dart';

void main() {
  late PendingApprovalManager manager;

  setUp(() {
    manager = PendingApprovalManager();
  });

  group('PendingApprovalManager', () {
    test('stores request ID from a valid link', () {
      final result = manager.handleLink(
        Uri.parse('myapp://approval/request_001'),
      );

      expect(result, isTrue);
      expect(manager.hasPendingRequest, isTrue);
      expect(manager.pendingRequestId, 'request_001');
    });

    test('rejects an invalid scheme', () {
      final result = manager.handleLink(
        Uri.parse('https://approval/request_001'),
      );

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isFalse);
    });

    test('rejects an invalid host', () {
      final result = manager.handleLink(
        Uri.parse('myapp://profile/request_001'),
      );

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isFalse);
    });

    test('rejects a link without a request ID', () {
      final result = manager.handleLink(
        Uri.parse('myapp://approval'),
      );

      expect(result, isFalse);
      expect(manager.hasPendingRequest, isFalse);
    });

    test('does not lose the pending request when the same link is received again', () {
      manager.handleLink(
        Uri.parse('myapp://approval/request_001'),
      );

      manager.handleLink(
        Uri.parse('myapp://approval/request_001'),
      );

      expect(manager.pendingRequestId, 'request_001');
    });

    test('clears the pending request', () {
      manager.handleLink(
        Uri.parse('myapp://approval/request_001'),
      );

      manager.clearPendingRequest();

      expect(manager.hasPendingRequest, isFalse);
      expect(manager.pendingRequestId, isNull);
    });
  });
}