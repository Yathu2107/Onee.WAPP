import 'package:dio/dio.dart';

import '../../../app_service/network/api_client_mixin.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/network/dio_client.dart';
import '../../../utils/constants.dart';
import '../model/address_models.dart';

class AddressRepository with ApiClientMixin {
  AddressRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  String get _base => AppConstants.addressesPath;

  Future<ApiResponse<List<SavedAddress>>> list() async {
    try {
      final response = await _dio.get(_base);
      return parseMessageResponse(response, (raw) {
        if (raw is! List) return <SavedAddress>[];
        return raw
            .whereType<Map>()
            .map((e) => SavedAddress.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<SavedAddress>> getById(int id) async {
    try {
      final response = await _dio.get('$_base/$id');
      return parseMessageResponse(
        response,
        (raw) => SavedAddress.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<SavedAddress>> create({
    required String label,
    required String addressLine,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await _dio.post(
        _base,
        data: {
          'label': label,
          'address_Line': addressLine,
          'latitude': latitude,
          'longitude': longitude,
          'is_Default': isDefault,
        },
      );
      return parseMessageResponse(
        response,
        (raw) => SavedAddress.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<SavedAddress>> update({
    required int id,
    required String label,
    required String addressLine,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      final response = await _dio.put(
        '$_base/$id',
        data: {
          'label': label,
          'address_Line': addressLine,
          'latitude': latitude,
          'longitude': longitude,
          'is_Default': isDefault,
        },
      );
      return parseMessageResponse(
        response,
        (raw) => SavedAddress.fromJson(Map<String, dynamic>.from(raw as Map)),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<String>> setDefault(int id) async {
    try {
      final response = await _dio.post('$_base/$id/set-default');
      return parseMessageResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<String>> delete(int id) async {
    try {
      final response = await _dio.delete('$_base/$id');
      return parseMessageResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
