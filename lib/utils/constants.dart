import '../app/routes/app_routes.dart';

class AppConstants {
  AppConstants._();

  static const String accountsPath = '/worker/accounts';
  static const String jobsPath = '/worker/jobs';
  static const String addressesPath = '/worker/addresses';
  static const String notificationsPath = '/worker/notifications';
  static const String categoriesPath = '/worker/categories';
  static const int otpLength = 6;
  static const int otpExpirySeconds = 5 * 60;
  static const int otpResendCooldownSeconds = 60;
  static const String phoneRegex = r'^07\d{8}$';
}

/// Routes nextStep values returned by verify-otp.
class AuthNextStep {
  AuthNextStep._();

  static const String homePage = 'home_page';
  static const String register = 'register';

  static String routeFor(String? nextStep) {
    if (nextStep == register) {
      return AppRoutes.completeRegistration;
    }
    // home_page — splash/skills gate may still redirect to select-skills
    return AppRoutes.home;
  }

  static bool isRegister(String? nextStep) => nextStep == register;
}
