import 'package:dio/dio.dart';

import 'api_response.dart';

/// Shared Message parsing used by feature repositories.
mixin ApiClientMixin {
  ApiResponse<T> parseMessageResponse<T>(
    Response response,
    T Function(dynamic) fromResult,
  ) {
    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    if (data is! Map) {
      throw ApiException(
        message: 'Unexpected server response.',
        statusCode: statusCode,
      );
    }

    final map = Map<String, dynamic>.from(data);
    final api = ApiResponse<T>.fromJson(map, fromResult);

    if (statusCode == 401 || statusCode == 404) {
      throw ApiException(
        message: api.text.isNotEmpty
            ? api.text
            : 'Session expired. Please log in again.',
        code: api.code.isNotEmpty ? api.code : 'UNAUTHORIZED',
        statusCode: statusCode,
      );
    }

    if (!api.isSuccess) {
      throw ApiException(
        message: api.text.isNotEmpty
            ? api.text
            : 'Something went wrong. Please try again.',
        code: api.code,
        statusCode: statusCode,
      );
    }

    return api;
  }

  ApiException mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final text = (map['text'] ?? '').toString();
      final code = (map['code'] ?? '').toString();
      return ApiException(
        message: text.isNotEmpty ? text : 'Request failed.',
        code: code,
        statusCode: statusCode,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: 'Connection timed out. Please try again.',
        statusCode: statusCode,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        message:
            'Cannot reach the server. Check BASE_URL and that the API is running.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: e.message ?? 'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
  }
}
