class SharePrefKey {
  static String isLogin = 'isLogin';

  static String gender = "Gender";
  static String workOutDay = "WorkOutDay";
  static String height = "Height";
  static String weight = "Weight";
  static String goalWeight = "GoalWeight";
  static String desiredWeight = "desiredWeight";
  static String age = "Age";
  static String bornDay = "BornDay";
  static String stoppingGoal = "StoppingGoal";
  static String firstMeal = "FirstMeal";
  static String secondMeal = "SecondMeal";
  static String thirdMeal = "ThirdMeal";
  static String calorie = "calorie";
  static String carbs = "carbs";
  static String fat = "fat";
  static String protein = "protein";
  static String isPremium = 'isPremium';
  static String premiumDate = 'PremiumDate';
  static String scanLimit = 'scanLimit';

  static String name = 'Name';
  static String userType = 'userType';
  static String isDarkMode = 'isDarkMode';

  static String countryCode = 'countryCode';
  static String languageCode = 'languageCode';
  static String language = 'language';
  static String hasSeenChatHistoryNotice = 'hasSeenChatHistoryNotice';
  static String onboardingCompleted = 'onboardingCompleted';
  static String hasSeenAppTips = 'hasSeenAppTips';
  static String hasCompletedTutorial = 'hasCompletedTutorial';

  static String stepGoal = 'stepGoal';

  // Streak
  static String streakCount = 'streakCount';
  static String lastActiveDate = 'lastActiveDate';
  static String streakHistory = 'streakHistory'; // List<String> of dates
  static String lastStreakShownDate = 'lastStreakShownDate'; // String date

  // Promo Code
  static String pendingPromoCode =
      'pendingPromoCode'; // Code entered during onboarding
  static String promoCodeActivated =
      'promoCodeActivated'; // Whether promo was validated
  static String activatedPromoCode =
      'activatedPromoCode'; // The actual activated code
}
