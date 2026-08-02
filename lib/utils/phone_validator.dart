import 'constants.dart';

class PhoneValidator {
  PhoneValidator._();

  static final RegExp _localPhone = RegExp(AppConstants.phoneRegex);

  /// Prefer local Sri Lankan format: 07XXXXXXXX
  static bool isValidLocal(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    return _localPhone.hasMatch(phone.trim());
  }

  static String? validate(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    if (!isValidLocal(phone)) {
      return 'Enter a valid Sri Lankan number (07XXXXXXXX)';
    }
    return null;
  }

  static String normalizeDigits(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }
}
