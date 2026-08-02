import 'package:dio/dio.dart';

import '../../../app_service/network/api_client_mixin.dart';
import '../../../app_service/network/api_response.dart';
import '../../../app_service/network/dio_client.dart';
import '../../../utils/constants.dart';
import '../../../utils/json_helpers.dart';
import '../model/category_models.dart';

class CategoryRepository with ApiClientMixin {
  CategoryRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  String get _base => AppConstants.categoriesPath;

  Future<ApiResponse<List<CategoryItem>>> listAll() async {
    try {
      final response = await _dio.get(_base);
      return parseMessageResponse(
        response,
        (raw) => JsonHelpers.parseObjectList(raw, CategoryItem.fromJson),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<List<WorkerCategoryItem>>> listMine() async {
    try {
      final response = await _dio.get('$_base/mine');
      return parseMessageResponse(
        response,
        (raw) =>
            JsonHelpers.parseObjectList(raw, WorkerCategoryItem.fromJson),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ApiResponse<String>> save(List<int> categoryIds) async {
    try {
      final response = await _dio.post(
        _base,
        data: {'categoryIds': categoryIds},
      );
      return parseMessageResponse(response, (raw) => raw?.toString() ?? '');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
