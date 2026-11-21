import 'package:auth_notification_app/features/notifications/domain/entities/approval_request.dart';

abstract class ApprovalRequestRepo {
  Future<ApprovalRequest> getApprovalRequest({
    required String requestId,
  });
}