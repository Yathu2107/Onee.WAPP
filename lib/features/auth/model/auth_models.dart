import '../../../utils/json_helpers.dart';

class OtpVerifyResult {
  const OtpVerifyResult({
    this.message,
    this.userName,
    this.email,
    this.role,
    this.token,
    this.refreshToken,
    this.refreshTokenExpiration,
    this.nextStep,
  });

  final String? message;
  final String? userName;
  final String? email;
  final String? role;
  final String? token;
  final String? refreshToken;
  final String? refreshTokenExpiration;
  final String? nextStep;

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResult(
      message: JsonHelpers.pickString(json, ['message', 'Message', 'text', 'Text']),
      userName: JsonHelpers.pickString(json, [
        'userName',
        'UserName',
        'name',
        'Name',
      ]),
      email: JsonHelpers.pickString(json, ['email', 'Email']),
      role: JsonHelpers.pickString(json, ['role', 'Role', 'userType', 'UserType']),
      token: JsonHelpers.pickString(json, ['token', 'Token', 'accessToken']),
      refreshToken: JsonHelpers.pickString(json, [
        'refreshToken',
        'RefreshToken',
      ]),
      refreshTokenExpiration: JsonHelpers.pickString(json, [
        'refreshTokenExpiration',
        'RefreshTokenExpiration',
      ]),
      nextStep: JsonHelpers.pickString(json, ['nextStep', 'NextStep']),
    );
  }
}

class WorkerDetails {
  const WorkerDetails({
    this.name,
    this.email,
    this.phoneNumber,
    this.proImg,
    this.isOnline,
    this.isActive,
    this.latitude,
    this.longitude,
    this.averageRating,
    this.ratingCount,
  });

  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? proImg;
  final bool? isOnline;
  final bool? isActive;
  final double? latitude;
  final double? longitude;
  final double? averageRating;
  final int? ratingCount;

  bool get hasName => name != null && name!.trim().isNotEmpty;

  factory WorkerDetails.fromJson(Map<String, dynamic> json) {
    return WorkerDetails(
      name: JsonHelpers.pickString(json, [
        'name',
        'Name',
        'userName',
        'UserName',
      ]),
      email: JsonHelpers.pickString(json, ['email', 'Email']),
      phoneNumber: JsonHelpers.pickString(json, [
        'phoneNumber',
        'PhoneNumber',
        'phone',
        'Phone',
      ]),
      proImg: JsonHelpers.pickString(json, [
        'proImg',
        'ProImg',
        'profileImage',
        'image',
        'Image',
      ]),
      isOnline: JsonHelpers.pickBool(json, ['isOnline', 'IsOnline']),
      isActive: JsonHelpers.pickBool(json, ['isActive', 'IsActive']),
      latitude: JsonHelpers.pickDouble(json, ['latitude', 'Latitude']),
      longitude: JsonHelpers.pickDouble(json, ['longitude', 'Longitude']),
      averageRating: JsonHelpers.pickDouble(json, [
        'averageRating',
        'AverageRating',
        'avgRating',
        'AvgRating',
      ]),
      ratingCount: JsonHelpers.pickInt(json, [
        'ratingCount',
        'RatingCount',
        'ratingsCount',
        'RatingsCount',
      ]),
    );
  }
}
