import 'package:flutter/material.dart';

import '../presentation/advertisement_player/advertisement_player.dart';
import '../presentation/business_details_preview/business_details_preview.dart';
import '../presentation/earnings/earnings_showcase_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/mobile_input/mobile_input_screen.dart';
import '../presentation/mobile_number_input/mobile_number_input.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/otp_verification/otp_verification.dart';
import '../presentation/qr_scanner_home/qr_scanner_home.dart';
import '../presentation/splash_screen/splash_screen.dart';

class AppRoutes {
  static const String splashScreen = '/';
  static const String onboardingFlow = '/onboarding-flow';
  static const String mobileNumberInput = '/mobile-number-input';
  static const String mobileInput = '/mobile-input';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String earningsShowcase = '/earnings-showcase';
  static const String qrScannerHome = '/qr-scanner-home';
  static const String businessDetailsPreview = '/business-details-preview';
  static const String advertisementPlayer = '/advertisement-player';

  static Map<String, WidgetBuilder> get routes => {
        splashScreen: (context) => const SplashScreen(),
        onboardingFlow: (context) => const OnboardingFlow(),
        mobileNumberInput: (context) => const MobileNumberInput(),
        mobileInput: (context) => const MobileInputScreen(),
        otpVerification: (context) => const OtpVerificationScreen(),
        home: (context) => const HomeScreen(),
        earningsShowcase: (context) => const EarningsShowcaseScreen(),
        qrScannerHome: (context) => const QRScannerHome(),
        businessDetailsPreview: (context) => const BusinessDetailsPreview(),
        advertisementPlayer: (context) => const AdvertisementPlayerScreen(),
      };
}
