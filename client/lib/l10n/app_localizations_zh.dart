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

  @override
  String get profileSetup => '个人资料设置';

  @override
  String get aboutYouPrefix => '关于';

  @override
  String get aboutYouHighlight => '你';

  @override
  String get basicInfoSubtitle => '告诉我们一些关于你的信息，以便我们的AI计算你精确的营养需求。';

  @override
  String get gender => '性别';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderOther => '其他';

  @override
  String get age => '年龄';

  @override
  String get unitYears => '岁';

  @override
  String get height => '身高';

  @override
  String get unitCm => '厘米';

  @override
  String get weight => '体重';

  @override
  String get unitKg => '公斤';

  @override
  String get householdDiners => '家庭用餐人数';

  @override
  String get householdDinersDescription => '有多少人经常一起用餐？这将调整份量和食材。';

  @override
  String get unitPersons => '人';

  @override
  String get estimatedBmi => '估算BMI';

  @override
  String get bmiUnderweight => '偏瘦';

  @override
  String get bmiNormal => '正常范围';

  @override
  String get bmiOverweight => '偏胖';

  @override
  String get bmiObesity => '肥胖';

  @override
  String get nextStep => '下一步';

  @override
  String get defineYourPrefix => '定义你的';

  @override
  String get defineYourHighlight => '节奏';

  @override
  String get occupationSubtitle => '选择你的职业和任何特定的健康阶段，帮助我们的AI根据你的活动水平定制营养方案。';

  @override
  String get aiAnalyzingMetabolicNeeds => 'AI 正在分析代谢需求...';

  @override
  String get skipForNow => '暂时跳过';

  @override
  String get allergiesAndRestrictions => '过敏与饮食限制';

  @override
  String get allergyWarning => '警告：请选择所有过敏原和饮食限制，以确保您的安全。';

  @override
  String get safetyPrefix => '安全';

  @override
  String get safetyHighlight => '第一';

  @override
  String get allergiesSubtitle => '选择任何过敏原或饮食限制。这非常重要——我们绝不会推荐可能伤害你的食材。';

  @override
  String get commonAllergens => '常见过敏原';

  @override
  String get dietaryPreferences => '饮食偏好';

  @override
  String get otherIngredientsToAvoid => '其他需要避免的食材';

  @override
  String get searchIngredients => '搜索食材...';

  @override
  String stepProgress(int current, int total) {
    return '第 $current/$total 步';
  }

  @override
  String get familyParameters => '家庭参数';

  @override
  String get howManyPeopleEating => '有多少人用餐？';

  @override
  String get generateStrategy => '生成策略';

  @override
  String get tagMuscleGain => '增肌';

  @override
  String get tagVegan => '纯素';

  @override
  String get tagHighProtein => '高蛋白';

  @override
  String get tagLowGI => '低GI';

  @override
  String get aiAnalyzingNeeds => 'AI 正在分析代谢需求...';

  @override
  String get buildingStrategy => '正在构建你的个性化策略';

  @override
  String get poweredByWiseDietAi => '由 WISEDIET AI 提供支持';

  @override
  String errorPrefix(String message) {
    return '错误：$message';
  }

  @override
  String get yourStrategy => '你的策略';

  @override
  String get yourPersonalizedStrategy => '你的个性化策略';

  @override
  String get healthStrategy => '健康策略';

  @override
  String get projectedImpact => '预期效果';

  @override
  String get focusBoost => '专注力提升';

  @override
  String get calorieTarget => '卡路里目标';

  @override
  String get yourPreferences => '你的偏好';

  @override
  String get adjust => '调整';

  @override
  String selectPreference(String preference) {
    return '选择$preference';
  }

  @override
  String get keyFocusAreas => '重点关注领域';

  @override
  String get startMyJourney => '开始我的旅程';

  @override
  String get preferencesInfoHint => '你可以随时在个人资料中更改这些偏好。';

  @override
  String get prefDailyFocus => '每日重点';

  @override
  String get prefMealFrequency => '用餐频次';

  @override
  String get prefCookingLevel => '烹饪水平';

  @override
  String get prefBudget => '预算';

  @override
  String get optMentalClarity => '思维清晰';

  @override
  String get optEnergy => '能量';

  @override
  String get optFatBurn => '燃脂';

  @override
  String get opt2Meals => '2餐';

  @override
  String get opt3Meals => '3餐';

  @override
  String get opt3MealsSnack => '3餐 + 1加餐';

  @override
  String get optBeginnerFriendly => '适合新手';

  @override
  String get optBalanced => '均衡';

  @override
  String get optAdvanced => '进阶';

  @override
  String get optBudgetLow => '¥70-¥140';

  @override
  String get optBudgetMid => '¥140-¥210';

  @override
  String get optBudgetHigh => '¥210-¥350';

  @override
  String get todaysSmartMenu => '今日智能菜单';

  @override
  String get selectionGuide => 'N+1 选择指南';

  @override
  String get selectionGuideBody => '为你的家庭选择至少N道菜。我们为每个用餐时段多准备了一个选项，方便灵活搭配。';

  @override
  String get dailyInsight => '每日洞察';

  @override
  String get dailyInsightBody => '早餐和午餐中增加蛋白质摄入可以减少晚间食欲，改善注意力稳定性。';

  @override
  String get mealBreakfast => '早餐';

  @override
  String get mealLunch => '午餐';

  @override
  String get mealSnack => '加餐';

  @override
  String get mealDinner => '晚餐';

  @override
  String caloriesKcal(int calories) {
    return '$calories 千卡';
  }

  @override
  String aiReason(String reason) {
    return 'AI推荐理由：$reason';
  }

  @override
  String selectedProgress(int selected, int total) {
    return '已选 $selected / $total';
  }

  @override
  String caloriesAndTime(int calories, int minutes) {
    return '$calories 千卡 • $minutes 分钟';
  }

  @override
  String menuConfirmed(int selected, int total) {
    return '菜单已确认 ($selected/$total)';
  }

  @override
  String confirmTodaysMenu(int count) {
    return '确认今日菜单 ($count)';
  }

  @override
  String get accountUnavailable => '账号暂不可用，稍后重试';
}
