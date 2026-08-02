import 'package:get/get.dart';

import '../../features/addresses/bindings/addresses_binding.dart';
import '../../features/addresses/form/address_form_binding.dart';
import '../../features/addresses/form/address_form_view.dart';
import '../../features/addresses/view/addresses_view.dart';
import '../../features/auth/complete_registration/bindings/complete_registration_binding.dart';
import '../../features/auth/complete_registration/view/complete_registration_view.dart';
import '../../features/auth/otp_verify/bindings/otp_verify_binding.dart';
import '../../features/auth/otp_verify/view/otp_verify_view.dart';
import '../../features/auth/phone_login/bindings/phone_login_binding.dart';
import '../../features/auth/phone_login/view/phone_login_view.dart';
import '../../features/jobs/chat/job_chat_binding.dart';
import '../../features/jobs/chat/job_chat_view.dart';
import '../../features/jobs/confirm/confirm_amount_binding.dart';
import '../../features/jobs/confirm/confirm_amount_view.dart';
import '../../features/jobs/detail/job_detail_binding.dart';
import '../../features/jobs/detail/job_detail_view.dart';
import '../../features/jobs/offer/offer_detail_binding.dart';
import '../../features/jobs/offer/offer_detail_view.dart';
import '../../features/location/set_location_binding.dart';
import '../../features/location/set_location_view.dart';
import '../../features/profile/edit_profile/bindings/edit_profile_binding.dart';
import '../../features/profile/edit_profile/view/edit_profile_view.dart';
import '../../features/shell/main_shell_view.dart';
import '../../features/skills/bindings/select_skills_binding.dart';
import '../../features/skills/view/select_skills_view.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/splash/view/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.phoneLogin,
      page: () => const PhoneLoginView(),
      binding: PhoneLoginBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.otpVerify,
      page: () => const OtpVerifyView(),
      binding: OtpVerifyBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.completeRegistration,
      page: () => const CompleteRegistrationView(),
      binding: CompleteRegistrationBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellView(),
      binding: MainShellBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.selectSkills,
      page: () => const SelectSkillsView(),
      binding: SelectSkillsBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.addresses,
      page: () => const AddressesView(),
      binding: AddressesBinding(),
    ),
    GetPage(
      name: AppRoutes.addressForm,
      page: () => const AddressFormView(),
      binding: AddressFormBinding(),
    ),
    GetPage(
      name: AppRoutes.offerDetail,
      page: () => const OfferDetailView(),
      binding: OfferDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.jobDetail,
      page: () => const JobDetailView(),
      binding: JobDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.jobChat,
      page: () => const JobChatView(),
      binding: JobChatBinding(),
    ),
    GetPage(
      name: AppRoutes.confirmAmount,
      page: () => const ConfirmAmountView(),
      binding: ConfirmAmountBinding(),
    ),
    GetPage(
      name: AppRoutes.setLocation,
      page: () => const SetLocationView(),
      binding: SetLocationBinding(),
    ),
  ];
}
