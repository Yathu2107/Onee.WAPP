import 'package:dio/dio.dart';

import '../../../app_service/network/api_response.dart';
import '../../../app_service/network/dio_client.dart';
import '../../../app_service/storage/secure_storage_service.dart';
import '../../../utils/constants.dart';
import '../model/auth_models.dart';

class AuthRepository {
  AuthRepository({
    required DioClient dioClient,
    required SecureStorageService storage,
  })  : _dio = dioClient.dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorageService _storage;

  static const _wrongAppMessage =
      'This number is a User account. Use the User app.';

  Future<ApiResponse<String>> verifyPhone(String phone) async {
    try {
      final response = await _dio.post(
        '${AppConstants.accountsPath}/verify-phone',
        queryParameters: {'phone': phone},
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<OtpVerifyResult>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.accountsPath}/verify-otp',
        data: {
          'phoneNumber': phoneNumber,
          'otp': otp,
        },
      );
      return _parseResponse(
        response,
        (raw) => OtpVerifyResult.fromJson(
          Map<String, dynamic>.from(raw as Map),
        ),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<String>> resendOtp(String phone) async {
    try {
      final response = await _dio.post(
        '${AppConstants.accountsPath}/resend-otp',
        queryParameters: {'phone': phone},
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<String>> register({
    required String name,
    required String email,
    required String phoneNumber,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'Name': name,
        'Email': email,
        'PhoneNumber': phoneNumber,
        if (imagePath != null && imagePath.isNotEmpty)
          'Image': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split(RegExp(r'[\\/]')).last,
          ),
      });

      final response = await _dio.post(
        '${AppConstants.accountsPath}/register',
        data: formData,
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Backend may return [WorkerDetails] directly or wrapped in a Message envelope.
  Future<ApiResponse<WorkerDetails>> getLoggedWorkerDetails() async {
    try {
      final response = await _dio.get(
        '${AppConstants.accountsPath}/get-logged-worker-details',
      );
      final statusCode = response.statusCode ?? 0;
      final data = response.data;

      if (statusCode == 401 || statusCode == 404) {
        final map =
            data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        throw ApiException(
          message: (map['text']?.toString().isNotEmpty ?? false)
              ? map['text'].toString()
              : 'Session expired. Please log in again.',
          code: (map['code']?.toString().isNotEmpty ?? false)
              ? map['code'].toString()
              : 'UNAUTHORIZED',
          statusCode: statusCode,
        );
      }

      if (data is! Map) {
        throw ApiException(
          message: 'Unexpected server response.',
          statusCode: statusCode,
        );
      }

      final map = Map<String, dynamic>.from(data);

      // Message envelope (status/code/text) vs raw worker payload.
      if (map.containsKey('status') && map['status'] != null) {
        return _parseResponse(
          response,
          (raw) {
            if (raw is Map) {
              return WorkerDetails.fromJson(Map<String, dynamic>.from(raw));
            }
            return WorkerDetails.fromJson(map);
          },
        );
      }

      final worker = WorkerDetails.fromJson(map);
      return ApiResponse<WorkerDetails>(
        status: 'S',
        text: 'OK',
        code: '200',
        result: worker,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<String>> logout() async {
    try {
      final response = await _dio.post(
        '${AppConstants.accountsPath}/Logout',
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Optional: register FCM device token after login.
  Future<ApiResponse<String>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.accountsPath}/register-device-token',
        data: {
          'token': token,
          'platform': platform,
        },
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<String>> removeDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _dio.delete(
        '${AppConstants.accountsPath}/device-token',
        data: {
          'token': token,
          'platform': platform,
        },
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<String>> updateWorker({
    required String name,
    required String email,
    required String phoneNumber,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'Name': name,
        'Email': email,
        'PhoneNumber': phoneNumber,
        if (imagePath != null && imagePath.isNotEmpty)
          'Image': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split(RegExp(r'[\\/]')).last,
          ),
      });
      final response = await _dio.put(
        '${AppConstants.accountsPath}/update-worker',
        data: formData,
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<String>> setLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.put(
        '${AppConstants.accountsPath}/set-location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ApiResponse<String>> setOnlineStatus(bool isOnline) async {
    try {
      final response = await _dio.put(
        '${AppConstants.accountsPath}/set-online-status',
        data: {'isOnline': isOnline},
      );
      return _parseResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> persistSession(OtpVerifyResult result) async {
    final token = result.token;
    if (token == null || token.isEmpty) {
      throw ApiException(message: 'Missing auth token from server.');
    }
    await _storage.saveTokens(
      token: token,
      refreshToken: result.refreshToken,
    );
  }

  Future<void> clearSession() => _storage.clearTokens();

  Future<bool> hasSession() => _storage.hasToken();

  ApiResponse<T> _parseResponse<T>(
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

    if (statusCode == 403 || api.code == 'WRONG_APP') {
      throw ApiException(
        message: _wrongAppMessage,
        code: 'WRONG_APP',
        statusCode: statusCode,
      );
    }

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
        message: _friendlyMessage(api.code, api.text),
        code: api.code,
        statusCode: statusCode,
      );
    }

    return api;
  }

  ApiException _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final code = (map['code'] ?? '').toString();
      final text = (map['text'] ?? '').toString();

      if (statusCode == 403 || code == 'WRONG_APP') {
        return ApiException(
          message: _wrongAppMessage,
          code: 'WRONG_APP',
          statusCode: statusCode,
        );
      }

      return ApiException(
        message: _friendlyMessage(code, text),
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

  String _friendlyMessage(String code, String text) {
    switch (code) {
      case 'INVALID_PHONE':
        return text.isNotEmpty ? text : 'Invalid phone number.';
      case 'OTP_COOLDOWN':
        return text.isNotEmpty
            ? text
            : 'Please wait 1 minute before requesting another OTP.';
      case 'OTP_SEND_FAILED':
        return text.isNotEmpty ? text : 'Failed to send OTP. Try again.';
      case 'ACCOUNT_BLOCKED':
        return text.isNotEmpty ? text : 'This account has been blocked.';
      case 'OTP_INVALID':
        return text.isNotEmpty ? text : 'Invalid OTP. Please try again.';
      case 'INVALID_MODEL':
        return text.isNotEmpty ? text : 'Please check the form and try again.';
      case 'REG_FAILED':
        return text.isNotEmpty ? text : 'Registration failed. Please try again.';
      case 'WRONG_APP':
        return _wrongAppMessage;
      default:
        return text.isNotEmpty
            ? text
            : 'Something went wrong. Please try again.';
    }
  }
}
