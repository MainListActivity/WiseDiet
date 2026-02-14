// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WiseDiet';

  @override
  String get helloWorld => 'Hello, World!';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get slogan => 'Smart Diet, Smart You';

  @override
  String get joinWiseDiet => 'Join WiseDiet';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithGithub => 'Continue with GitHub';

  @override
  String get orLoginWithEmail => 'OR LOGIN WITH EMAIL';

  @override
  String get signInWithEmail => 'Sign in with Email';

  @override
  String get termsPrefix =>
      'By continuing, you acknowledge that you have\\nread and agree to our ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get and => ' & ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get period => '.';

  @override
  String get loading => 'LOADING';
}
