import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WiseDiet'**
  String get appTitle;

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello, World!'**
  String get helloWorld;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @slogan.
  ///
  /// In en, this message translates to:
  /// **'Smart Diet, Smart You'**
  String get slogan;

  /// No description provided for @joinWiseDiet.
  ///
  /// In en, this message translates to:
  /// **'Join WiseDiet'**
  String get joinWiseDiet;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithGithub.
  ///
  /// In en, this message translates to:
  /// **'Continue with GitHub'**
  String get continueWithGithub;

  /// No description provided for @orLoginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'OR LOGIN WITH EMAIL'**
  String get orLoginWithEmail;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signInWithEmail;

  /// No description provided for @termsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you acknowledge that you have\\nread and agree to our '**
  String get termsPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' & '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get period;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get loading;

  /// No description provided for @profileSetup.
  ///
  /// In en, this message translates to:
  /// **'Profile Setup'**
  String get profileSetup;

  /// No description provided for @aboutYouPrefix.
  ///
  /// In en, this message translates to:
  /// **'About '**
  String get aboutYouPrefix;

  /// No description provided for @aboutYouHighlight.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get aboutYouHighlight;

  /// No description provided for @basicInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself so our AI can calculate your precise nutritional needs.'**
  String get basicInfoSubtitle;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @unitYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get unitYears;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @unitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @householdDiners.
  ///
  /// In en, this message translates to:
  /// **'Household Diners'**
  String get householdDiners;

  /// No description provided for @householdDinersDescription.
  ///
  /// In en, this message translates to:
  /// **'How many people regularly eat together? This adjusts portion sizes and ingredients.'**
  String get householdDinersDescription;

  /// No description provided for @unitPersons.
  ///
  /// In en, this message translates to:
  /// **'persons'**
  String get unitPersons;

  /// No description provided for @estimatedBmi.
  ///
  /// In en, this message translates to:
  /// **'Estimated BMI'**
  String get estimatedBmi;

  /// No description provided for @bmiUnderweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal range'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiOverweight;

  /// No description provided for @bmiObesity.
  ///
  /// In en, this message translates to:
  /// **'Obesity'**
  String get bmiObesity;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @defineYourPrefix.
  ///
  /// In en, this message translates to:
  /// **'Define Your '**
  String get defineYourPrefix;

  /// No description provided for @defineYourHighlight.
  ///
  /// In en, this message translates to:
  /// **'Rhythm'**
  String get defineYourHighlight;

  /// No description provided for @occupationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your occupation and any specific health stages to help our AI tailor nutrition to your activity levels.'**
  String get occupationSubtitle;

  /// No description provided for @aiAnalyzingMetabolicNeeds.
  ///
  /// In en, this message translates to:
  /// **'AI ANALYZING METABOLIC NEEDS...'**
  String get aiAnalyzingMetabolicNeeds;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @allergiesAndRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Allergies & Restrictions'**
  String get allergiesAndRestrictions;

  /// No description provided for @allergyWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Please select all allergies and restrictions to ensure your safety.'**
  String get allergyWarning;

  /// No description provided for @safetyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Safety '**
  String get safetyPrefix;

  /// No description provided for @safetyHighlight.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get safetyHighlight;

  /// No description provided for @allergiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select any allergies or dietary restrictions. This is critical — we\'ll never recommend ingredients that could harm you.'**
  String get allergiesSubtitle;

  /// No description provided for @commonAllergens.
  ///
  /// In en, this message translates to:
  /// **'Common Allergens'**
  String get commonAllergens;

  /// No description provided for @dietaryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Dietary Preferences'**
  String get dietaryPreferences;

  /// No description provided for @otherIngredientsToAvoid.
  ///
  /// In en, this message translates to:
  /// **'Other Ingredients to Avoid'**
  String get otherIngredientsToAvoid;

  /// No description provided for @searchIngredients.
  ///
  /// In en, this message translates to:
  /// **'Search ingredients...'**
  String get searchIngredients;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String stepProgress(int current, int total);

  /// No description provided for @familyParameters.
  ///
  /// In en, this message translates to:
  /// **'Family Parameters'**
  String get familyParameters;

  /// No description provided for @howManyPeopleEating.
  ///
  /// In en, this message translates to:
  /// **'How many people are eating?'**
  String get howManyPeopleEating;

  /// No description provided for @generateStrategy.
  ///
  /// In en, this message translates to:
  /// **'Generate Strategy'**
  String get generateStrategy;

  /// No description provided for @tagMuscleGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle Gain'**
  String get tagMuscleGain;

  /// No description provided for @tagVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get tagVegan;

  /// No description provided for @tagHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High Protein'**
  String get tagHighProtein;

  /// No description provided for @tagLowGI.
  ///
  /// In en, this message translates to:
  /// **'Low GI'**
  String get tagLowGI;

  /// No description provided for @aiAnalyzingNeeds.
  ///
  /// In en, this message translates to:
  /// **'AI Analyzing metabolic needs...'**
  String get aiAnalyzingNeeds;

  /// No description provided for @buildingStrategy.
  ///
  /// In en, this message translates to:
  /// **'Building your personalized strategy'**
  String get buildingStrategy;

  /// No description provided for @poweredByWiseDietAi.
  ///
  /// In en, this message translates to:
  /// **'POWERED BY WISEDIET AI'**
  String get poweredByWiseDietAi;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @yourStrategy.
  ///
  /// In en, this message translates to:
  /// **'Your Strategy'**
  String get yourStrategy;

  /// No description provided for @yourPersonalizedStrategy.
  ///
  /// In en, this message translates to:
  /// **'Your Personalized Strategy'**
  String get yourPersonalizedStrategy;

  /// No description provided for @healthStrategy.
  ///
  /// In en, this message translates to:
  /// **'Health Strategy'**
  String get healthStrategy;

  /// No description provided for @projectedImpact.
  ///
  /// In en, this message translates to:
  /// **'Projected Impact'**
  String get projectedImpact;

  /// No description provided for @focusBoost.
  ///
  /// In en, this message translates to:
  /// **'Focus Boost'**
  String get focusBoost;

  /// No description provided for @calorieTarget.
  ///
  /// In en, this message translates to:
  /// **'Calorie Target'**
  String get calorieTarget;

  /// No description provided for @yourPreferences.
  ///
  /// In en, this message translates to:
  /// **'Your Preferences'**
  String get yourPreferences;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @selectPreference.
  ///
  /// In en, this message translates to:
  /// **'Select {preference}'**
  String selectPreference(String preference);

  /// No description provided for @keyFocusAreas.
  ///
  /// In en, this message translates to:
  /// **'Key Focus Areas'**
  String get keyFocusAreas;

  /// No description provided for @startMyJourney.
  ///
  /// In en, this message translates to:
  /// **'Start My Journey'**
  String get startMyJourney;

  /// No description provided for @preferencesInfoHint.
  ///
  /// In en, this message translates to:
  /// **'You can change these preferences anytime from your profile.'**
  String get preferencesInfoHint;

  /// No description provided for @prefDailyFocus.
  ///
  /// In en, this message translates to:
  /// **'Daily Focus'**
  String get prefDailyFocus;

  /// No description provided for @prefMealFrequency.
  ///
  /// In en, this message translates to:
  /// **'Meal Frequency'**
  String get prefMealFrequency;

  /// No description provided for @prefCookingLevel.
  ///
  /// In en, this message translates to:
  /// **'Cooking Level'**
  String get prefCookingLevel;

  /// No description provided for @prefBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get prefBudget;

  /// No description provided for @optMentalClarity.
  ///
  /// In en, this message translates to:
  /// **'Mental Clarity'**
  String get optMentalClarity;

  /// No description provided for @optEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get optEnergy;

  /// No description provided for @optFatBurn.
  ///
  /// In en, this message translates to:
  /// **'Fat Burn'**
  String get optFatBurn;

  /// No description provided for @opt2Meals.
  ///
  /// In en, this message translates to:
  /// **'2 meals'**
  String get opt2Meals;

  /// No description provided for @opt3Meals.
  ///
  /// In en, this message translates to:
  /// **'3 meals'**
  String get opt3Meals;

  /// No description provided for @opt3MealsSnack.
  ///
  /// In en, this message translates to:
  /// **'3 meals + 1 snack'**
  String get opt3MealsSnack;

  /// No description provided for @optBeginnerFriendly.
  ///
  /// In en, this message translates to:
  /// **'Beginner Friendly'**
  String get optBeginnerFriendly;

  /// No description provided for @optBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get optBalanced;

  /// No description provided for @optAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get optAdvanced;

  /// No description provided for @optBudgetLow.
  ///
  /// In en, this message translates to:
  /// **'\$10-\$20'**
  String get optBudgetLow;

  /// No description provided for @optBudgetMid.
  ///
  /// In en, this message translates to:
  /// **'\$20-\$30'**
  String get optBudgetMid;

  /// No description provided for @optBudgetHigh.
  ///
  /// In en, this message translates to:
  /// **'\$30-\$50'**
  String get optBudgetHigh;

  /// No description provided for @todaysSmartMenu.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Smart Menu'**
  String get todaysSmartMenu;

  /// No description provided for @selectionGuide.
  ///
  /// In en, this message translates to:
  /// **'N+1 Selection Guide'**
  String get selectionGuide;

  /// No description provided for @selectionGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Choose at least N dishes for your household. We prepared one extra option per meal slot for flexibility.'**
  String get selectionGuideBody;

  /// No description provided for @dailyInsight.
  ///
  /// In en, this message translates to:
  /// **'Daily Insight'**
  String get dailyInsight;

  /// No description provided for @dailyInsightBody.
  ///
  /// In en, this message translates to:
  /// **'Higher protein in breakfast and lunch can reduce evening cravings and improve concentration stability.'**
  String get dailyInsightBody;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealSnack;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @caloriesKcal.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String caloriesKcal(int calories);

  /// No description provided for @aiReason.
  ///
  /// In en, this message translates to:
  /// **'AI reason: {reason}'**
  String aiReason(String reason);

  /// No description provided for @selectedProgress.
  ///
  /// In en, this message translates to:
  /// **'{selected} / {total} selected'**
  String selectedProgress(int selected, int total);

  /// No description provided for @caloriesAndTime.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal • {minutes} mins'**
  String caloriesAndTime(int calories, int minutes);

  /// No description provided for @menuConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Menu confirmed ({selected}/{total})'**
  String menuConfirmed(int selected, int total);

  /// No description provided for @confirmTodaysMenu.
  ///
  /// In en, this message translates to:
  /// **'Confirm Today\'s Menu ({count})'**
  String confirmTodaysMenu(int count);

  /// No description provided for @accountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account unavailable, please try again later'**
  String get accountUnavailable;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navShopping;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @shoppingPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingPlaceholderTitle;

  /// No description provided for @shoppingPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Your smart shopping list is coming soon.'**
  String get shoppingPlaceholderBody;

  /// No description provided for @historyPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'History & Me'**
  String get historyPlaceholderTitle;

  /// No description provided for @historyPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Your meal history and insights are coming soon.'**
  String get historyPlaceholderBody;

  /// No description provided for @profileCardViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get profileCardViewProfile;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again.'**
  String get profileLogoutConfirmBody;

  /// No description provided for @profileLogoutConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileLogoutConfirmCancel;

  /// No description provided for @profileLogoutConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogoutConfirmAction;

  /// No description provided for @profileSectionBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get profileSectionBasicInfo;

  /// No description provided for @profileSectionHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get profileSectionHousehold;

  /// No description provided for @profileSectionOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation Tags'**
  String get profileSectionOccupation;

  /// No description provided for @profileSectionDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet & Allergies'**
  String get profileSectionDiet;

  /// No description provided for @profileFieldGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileFieldGender;

  /// No description provided for @profileFieldAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileFieldAge;

  /// No description provided for @profileFieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileFieldHeight;

  /// No description provided for @profileFieldWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileFieldWeight;

  /// No description provided for @profileFieldFamilyMembers.
  ///
  /// In en, this message translates to:
  /// **'Household Diners'**
  String get profileFieldFamilyMembers;

  /// No description provided for @profileFieldOccupationTags.
  ///
  /// In en, this message translates to:
  /// **'Occupation Tags'**
  String get profileFieldOccupationTags;

  /// No description provided for @profileFieldAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get profileFieldAllergens;

  /// No description provided for @profileFieldDietaryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Dietary Preferences'**
  String get profileFieldDietaryPreferences;

  /// No description provided for @profileFieldCustomAvoid.
  ///
  /// In en, this message translates to:
  /// **'Custom Avoid'**
  String get profileFieldCustomAvoid;

  /// No description provided for @profileEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEditButton;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get profileSaveError;

  /// No description provided for @profileNoTags.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get profileNoTags;

  /// No description provided for @profileNoCustomAvoid.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get profileNoCustomAvoid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
