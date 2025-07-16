import 'package:flutter/material.dart';

import '../presentation/home/home_screen.dart';
import '../presentation/mobile_input/mobile_input_screen.dart';
import '../presentation/mobile_number_input/mobile_number_input.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/otp_verification/otp_verification.dart';
import '../presentation/splash_screen/splash_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String mobileInput = '/mobile-input';
  static const String mobileNumberInput = '/mobile-number-input';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String qrScanner = '/qr-scanner';
  static const String adViewer = '/ad-viewer';
  static const String payoutSuccess = '/payout-success';
  static const String profile = '/profile';
  static const String earnings = '/earnings';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    mobileInput: (context) => const MobileInputScreen(),
    mobileNumberInput: (context) => const MobileNumberInput(),
    otpVerification: (context) => const OtpVerificationScreen(),
    home: (context) => const HomeScreen(),
    // TODO: Add other routes when screens are implemented
  };
}
