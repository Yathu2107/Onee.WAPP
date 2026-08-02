import 'package:dio/dio.dart';

import '../../../app_service/network/api_client_mixin.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/network/dio_client.dart';
import '../../../utils/constants.dart';
import '../model/notification_models.dart';

class NotificationRepository with ApiClientMixin {
  NotificationRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  String get _base => AppConstants.notificationsPath;

  Future<ApiResponse<List<AppNotification>>> list() async {
    try {
      final response = await _dio.get(_base);
      return parseMessageResponse(response, (raw) {
        if (raw is! List) return <AppNotification>[];
        return raw
            .whereType<Map>()
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<int>> unreadCount() async {
    try {
      final response = await _dio.get('$_base/unread-count');
      return parseMessageResponse(response, (raw) {
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse(raw?.toString() ?? '') ?? 0;
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<String>> markRead(int id) async {
    try {
      final response = await _dio.post('$_base/$id/read');
      return parseMessageResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<String>> markAllRead() async {
    try {
      final response = await _dio.post('$_base/read-all');
      return parseMessageResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
