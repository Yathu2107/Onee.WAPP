import 'package:dio/dio.dart';

import '../../../app_service/network/api_client_mixin.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/network/dio_client.dart';
import '../../../utils/constants.dart';
import '../../../utils/json_helpers.dart';
import '../model/job_models.dart';

class JobRepository with ApiClientMixin {
  JobRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  String get _base => AppConstants.jobsPath;

  Future<ApiResponse<List<JobListItem>>> getOffers() async {
    try {
      final response = await _dio.get('$_base/offers');
      return parseMessageResponse(
        response,
        (raw) => JsonHelpers.parseObjectList(raw, JobListItem.fromJson),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<List<JobListItem>>> getMyJobs() async {
    try {
      final response = await _dio.get('$_base/mine');
      return parseMessageResponse(
        response,
        (raw) => JsonHelpers.parseObjectList(raw, JobListItem.fromJson),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<JobDetail>> getJob(int id) async {
    try {
      final response = await _dio.get('$_base/$id');
      return parseMessageResponse(
        response,
        (raw) => JobDetail.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<JobDetail>> accept(int id) async {
    try {
      final response = await _dio.post('$_base/$id/accept');
      return parseMessageResponse(
        response,
        (raw) => JobDetail.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<JobDetail>> decline(int id) async {
    try {
      final response = await _dio.post('$_base/$id/decline');
      return parseMessageResponse(
        response,
        (raw) => JobDetail.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<JobDetail>> confirm(int id, double amount) async {
    try {
      final response = await _dio.post(
        '$_base/$id/confirm',
        data: {'amount': amount},
      );
      return parseMessageResponse(
        response,
        (raw) => JobDetail.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<JobDetail>> complete(int id) async {
    try {
      final response = await _dio.post('$_base/$id/complete');
      return parseMessageResponse(
        response,
        (raw) => JobDetail.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<List<JobChatMessage>>> getChat(int jobId) async {
    try {
      final response = await _dio.get('$_base/$jobId/chat');
      return parseMessageResponse(
        response,
        (raw) => JsonHelpers.parseObjectList(raw, JobChatMessage.fromJson),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<JobChatMessage>> sendChat(int jobId, String message) async {
    try {
      final response = await _dio.post(
        '$_base/$jobId/chat',
        data: {'message': message},
      );
      return parseMessageResponse(
        response,
        (raw) => JobChatMessage.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
