// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'WiseDiet';

  @override
  String get helloWorld => '你好，世界！';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get slogan => '智慧饮食，智慧你';

  @override
  String get joinWiseDiet => '加入 WiseDiet';

  @override
  String get continueWithGoogle => '使用 Google 继续';

  @override
  String get continueWithGithub => '使用 GitHub 继续';

  @override
  String get orLoginWithEmail => '或使用邮箱登录';

  @override
  String get signInWithEmail => '使用邮箱登录';

  @override
  String get termsPrefix => '继续即表示你已阅读并同意我们的';

  @override
  String get termsOfService => '服务条款';

  @override
  String get and => '与';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get period => '。';

  @override
  String get loading => '加载中';
}
