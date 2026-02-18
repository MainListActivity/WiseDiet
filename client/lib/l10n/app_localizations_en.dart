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

  @override
  String get profileSetup => 'Profile Setup';

  @override
  String get aboutYouPrefix => 'About ';

  @override
  String get aboutYouHighlight => 'You';

  @override
  String get basicInfoSubtitle =>
      'Tell us a bit about yourself so our AI can calculate your precise nutritional needs.';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get age => 'Age';

  @override
  String get unitYears => 'years';

  @override
  String get height => 'Height';

  @override
  String get unitCm => 'cm';

  @override
  String get weight => 'Weight';

  @override
  String get unitKg => 'kg';

  @override
  String get householdDiners => 'Household Diners';

  @override
  String get householdDinersDescription =>
      'How many people regularly eat together? This adjusts portion sizes and ingredients.';

  @override
  String get unitPersons => 'persons';

  @override
  String get estimatedBmi => 'Estimated BMI';

  @override
  String get bmiUnderweight => 'Underweight';

  @override
  String get bmiNormal => 'Normal range';

  @override
  String get bmiOverweight => 'Overweight';

  @override
  String get bmiObesity => 'Obesity';

  @override
  String get nextStep => 'Next Step';

  @override
  String get defineYourPrefix => 'Define Your ';

  @override
  String get defineYourHighlight => 'Rhythm';

  @override
  String get occupationSubtitle =>
      'Select your occupation and any specific health stages to help our AI tailor nutrition to your activity levels.';

  @override
  String get aiAnalyzingMetabolicNeeds => 'AI ANALYZING METABOLIC NEEDS...';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get allergiesAndRestrictions => 'Allergies & Restrictions';

  @override
  String get allergyWarning =>
      'WARNING: Please select all allergies and restrictions to ensure your safety.';

  @override
  String get safetyPrefix => 'Safety ';

  @override
  String get safetyHighlight => 'First';

  @override
  String get allergiesSubtitle =>
      'Select any allergies or dietary restrictions. This is critical — we\'ll never recommend ingredients that could harm you.';

  @override
  String get commonAllergens => 'Common Allergens';

  @override
  String get dietaryPreferences => 'Dietary Preferences';

  @override
  String get otherIngredientsToAvoid => 'Other Ingredients to Avoid';

  @override
  String get searchIngredients => 'Search ingredients...';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get familyParameters => 'Family Parameters';

  @override
  String get howManyPeopleEating => 'How many people are eating?';

  @override
  String get generateStrategy => 'Generate Strategy';

  @override
  String get tagMuscleGain => 'Muscle Gain';

  @override
  String get tagVegan => 'Vegan';

  @override
  String get tagHighProtein => 'High Protein';

  @override
  String get tagLowGI => 'Low GI';

  @override
  String get aiAnalyzingNeeds => 'AI Analyzing metabolic needs...';

  @override
  String get buildingStrategy => 'Building your personalized strategy';

  @override
  String get poweredByWiseDietAi => 'POWERED BY WISEDIET AI';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get yourStrategy => 'Your Strategy';

  @override
  String get yourPersonalizedStrategy => 'Your Personalized Strategy';

  @override
  String get healthStrategy => 'Health Strategy';

  @override
  String get projectedImpact => 'Projected Impact';

  @override
  String get focusBoost => 'Focus Boost';

  @override
  String get calorieTarget => 'Calorie Target';

  @override
  String get yourPreferences => 'Your Preferences';

  @override
  String get adjust => 'Adjust';

  @override
  String selectPreference(String preference) {
    return 'Select $preference';
  }

  @override
  String get keyFocusAreas => 'Key Focus Areas';

  @override
  String get startMyJourney => 'Start My Journey';

  @override
  String get preferencesInfoHint =>
      'You can change these preferences anytime from your profile.';

  @override
  String get prefDailyFocus => 'Daily Focus';

  @override
  String get prefMealFrequency => 'Meal Frequency';

  @override
  String get prefCookingLevel => 'Cooking Level';

  @override
  String get prefBudget => 'Budget';

  @override
  String get optMentalClarity => 'Mental Clarity';

  @override
  String get optEnergy => 'Energy';

  @override
  String get optFatBurn => 'Fat Burn';

  @override
  String get opt2Meals => '2 meals';

  @override
  String get opt3Meals => '3 meals';

  @override
  String get opt3MealsSnack => '3 meals + 1 snack';

  @override
  String get optBeginnerFriendly => 'Beginner Friendly';

  @override
  String get optBalanced => 'Balanced';

  @override
  String get optAdvanced => 'Advanced';

  @override
  String get optBudgetLow => '\$10-\$20';

  @override
  String get optBudgetMid => '\$20-\$30';

  @override
  String get optBudgetHigh => '\$30-\$50';

  @override
  String get todaysSmartMenu => 'Today\'s Smart Menu';

  @override
  String get selectionGuide => 'N+1 Selection Guide';

  @override
  String get selectionGuideBody =>
      'Choose at least N dishes for your household. We prepared one extra option per meal slot for flexibility.';

  @override
  String get dailyInsight => 'Daily Insight';

  @override
  String get dailyInsightBody =>
      'Higher protein in breakfast and lunch can reduce evening cravings and improve concentration stability.';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealSnack => 'Snack';

  @override
  String get mealDinner => 'Dinner';

  @override
  String caloriesKcal(int calories) {
    return '$calories kcal';
  }

  @override
  String aiReason(String reason) {
    return 'AI reason: $reason';
  }

  @override
  String selectedProgress(int selected, int total) {
    return '$selected / $total selected';
  }

  @override
  String caloriesAndTime(int calories, int minutes) {
    return '$calories kcal • $minutes mins';
  }

  @override
  String menuConfirmed(int selected, int total) {
    return 'Menu confirmed ($selected/$total)';
  }

  @override
  String confirmTodaysMenu(int count) {
    return 'Confirm Today\'s Menu ($count)';
  }

  @override
  String get accountUnavailable =>
      'Account unavailable, please try again later';

  @override
  String get navToday => 'Today';

  @override
  String get navShopping => 'Shopping';

  @override
  String get navHistory => 'History';

  @override
  String get shoppingPlaceholderTitle => 'Shopping List';

  @override
  String get shoppingPlaceholderBody =>
      'Your smart shopping list is coming soon.';

  @override
  String get historyPlaceholderTitle => 'History & Me';

  @override
  String get historyPlaceholderBody =>
      'Your meal history and insights are coming soon.';

  @override
  String get profileCardViewProfile => 'View profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutConfirmTitle => 'Log out?';

  @override
  String get profileLogoutConfirmBody => 'You will need to sign in again.';

  @override
  String get profileLogoutConfirmCancel => 'Cancel';

  @override
  String get profileLogoutConfirmAction => 'Log out';

  @override
  String get profileSectionBasicInfo => 'Basic Info';

  @override
  String get profileSectionHousehold => 'Household';

  @override
  String get profileSectionOccupation => 'Occupation Tags';

  @override
  String get profileSectionDiet => 'Diet & Allergies';

  @override
  String get profileFieldGender => 'Gender';

  @override
  String get profileFieldAge => 'Age';

  @override
  String get profileFieldHeight => 'Height';

  @override
  String get profileFieldWeight => 'Weight';

  @override
  String get profileFieldFamilyMembers => 'Household Diners';

  @override
  String get profileFieldOccupationTags => 'Occupation Tags';

  @override
  String get profileFieldAllergens => 'Allergens';

  @override
  String get profileFieldDietaryPreferences => 'Dietary Preferences';

  @override
  String get profileFieldCustomAvoid => 'Custom Avoid';

  @override
  String get profileEditButton => 'Edit';

  @override
  String get profileSaveError => 'Failed to save. Please try again.';

  @override
  String get profileNoTags => 'None selected';

  @override
  String get profileNoCustomAvoid => 'None';
}
