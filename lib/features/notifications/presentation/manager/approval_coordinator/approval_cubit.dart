import 'package:auth_notification_app/features/notifications/domain/entities/approval_request.dart';
import 'package:auth_notification_app/features/notifications/domain/usecases/get_approval_request_usecase.dart';
import 'package:auth_notification_app/features/notifications/presentation/manager/approval_coordinator/approval_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApprovalCubit extends Cubit<ApprovalState> {
  final GetApprovalRequestUseCase getApprovalRequestUseCase;

  bool _isProcessing = false;

  ApprovalCubit({required this.getApprovalRequestUseCase})
    : super(const ApprovalInitial());

  Future<ApprovalRequest?> fetchRequest({required String requestId}) async {
    if (_isProcessing) return null;

    _isProcessing = true;

    emit(const ApprovalLoading());

    try {
      final request = await getApprovalRequestUseCase(requestId: requestId);

      if (isClosed) return null;

      emit(ApprovalLoaded(request));

      return request;
    } catch (_) {
      if (!isClosed) {
        emit(const ApprovalFailure('Failed to load approval request.'));
      }
    } finally {
      _isProcessing = false;
    }
    return null;
  }

  void reset() {
    if (_isProcessing) return;

    emit(const ApprovalInitial());
  }
}
