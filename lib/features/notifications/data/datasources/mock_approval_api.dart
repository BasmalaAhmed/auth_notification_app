import 'package:auth_notification_app/core/errors/api_exception.dart';

class MockApprovalApi {
  Future<Map<String, dynamic>> getApprovalRequest({
    required String accessToken,
    required String requestId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (accessToken != 'mock_access_token_001' &&
        accessToken != 'mock_access_token_002') {
      throw const ApiException(
        statusCode: 401,
        message: 'Unauthorized',
      );
    }

    if (requestId == 'request_forbidden_001') {
      throw const ApiException(
        statusCode: 403,
        message: 'You are not allowed to access this request.',
      );
    }

    if (requestId != 'request_001') {
      throw const ApiException(
        statusCode: 404,
        message: 'Approval request not found.',
      );
    }

    return {
      'request_id': 'request_001',
      'title': 'New Shop Approval',
      'description': 'A new shop is waiting for your approval.',
    };
  }
}