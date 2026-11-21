import 'package:auth_notification_app/features/notifications/domain/entities/approval_request.dart';
import 'package:auth_notification_app/features/notifications/domain/repos/approval_request_repo.dart';

class GetApprovalRequestUseCase {
  final ApprovalRequestRepo approvalRequestRepo;

  GetApprovalRequestUseCase(this.approvalRequestRepo);

  Future<ApprovalRequest> call({
    required String requestId,
  }) {
    return approvalRequestRepo.getApprovalRequest(
      requestId: requestId,
    );
  }
}