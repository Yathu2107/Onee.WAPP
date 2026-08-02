class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    required this.text,
    required this.code,
    this.result,
  });

  final String status;
  final String text;
  final String code;
  final T? result;

  bool get isSuccess => status.toUpperCase() == 'S';

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromResult,
  ) {
    final rawResult = json['result'] ?? json['Result'];
    T? result;
    if (fromResult != null && rawResult != null) {
      result = fromResult(rawResult);
    } else if (rawResult is T) {
      result = rawResult;
    }

    return ApiResponse<T>(
      status: (json['status'] ?? json['Status'] ?? '').toString(),
      text: (json['text'] ?? json['Text'] ?? '').toString(),
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      result: result,
    );
  }
}

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.code = '',
    this.statusCode,
  });

  final String message;
  final String code;
  final int? statusCode;

  @override
  String toString() => message;
}
