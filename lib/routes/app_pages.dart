import 'package:macroaize/screens/AdjustGoals/adjust_goals_binding.dart';
import 'package:macroaize/screens/AdjustGoals/adjust_goals_view.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_binding.dart';
import 'package:macroaize/screens/AnalyticsScreen/analytics_view.dart';
import 'package:macroaize/screens/ChatHistoryScreen/chat_history_binding.dart';
import 'package:macroaize/screens/ChatHistoryScreen/chat_history_view.dart';
import 'package:macroaize/screens/ChatScreen/chat_binding.dart';
import 'package:macroaize/screens/ChatScreen/chat_view.dart';
import 'package:macroaize/screens/HomeScreen/home_binding.dart';
import 'package:macroaize/screens/HomeScreen/home_view.dart';
import 'package:macroaize/screens/LocalFoodScreen/local_food_binding.dart';
import 'package:macroaize/screens/LocalFoodScreen/local_food_view.dart';
import 'package:macroaize/screens/PersonalDetailsScreen/personal_details_binding.dart';
import 'package:macroaize/screens/PersonalDetailsScreen/personal_details_view.dart';
import 'package:macroaize/screens/PremiumScreen/premium_binding.dart';
import 'package:macroaize/screens/PremiumScreen/premium_view.dart';
import 'package:macroaize/screens/RecipesScreen/recipes_binding.dart';
import 'package:macroaize/screens/RecipesScreen/recipes_view.dart';
import 'package:macroaize/screens/ScanCalorieScreen/scan_calorie_binding.dart';
import 'package:macroaize/screens/ScanCalorieScreen/scan_calorie_view.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_binding.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_view.dart';
import 'package:macroaize/screens/SettingScreen/setting_binding.dart';
import 'package:macroaize/screens/SettingScreen/setting_view.dart';
import 'package:macroaize/screens/SignUpScreens/singup_binding.dart';
import 'package:macroaize/screens/SignUpScreens/singup_view.dart';
import 'package:macroaize/screens/historyScreen/history_binding.dart';
import 'package:macroaize/screens/historyScreen/history_view.dart';
import 'package:macroaize/screens/languageScreen/language_binding.dart';
import 'package:macroaize/screens/languageScreen/language_view.dart';
import 'package:macroaize/screens/leadingScreen/leading_binding.dart';
import 'package:macroaize/screens/leadingScreen/leading_view.dart';
import 'package:macroaize/screens/onBording/onboarding_binding.dart';
import 'package:macroaize/screens/splash/splash_binding.dart';
import 'package:macroaize/screens/splash/splash_view.dart';
import 'package:macroaize/screens/welcome/welcome_binding.dart';
import 'package:macroaize/screens/welcome/welcome_view.dart';
import 'package:macroaize/screens/planIntro/plan_intro_binding.dart';
import 'package:macroaize/screens/planIntro/plan_intro_view.dart';
import 'package:macroaize/screens/transition/transition_binding.dart';
import 'package:macroaize/screens/transition/transition_view.dart';
import 'package:macroaize/screens/WithdrawalHistoryScreen/withdrawal_history_binding.dart';
import 'package:macroaize/screens/WithdrawalHistoryScreen/withdrawal_history_view.dart';
import 'package:get/get.dart';
import 'package:macroaize/screens/AccountDetails/account_details_view.dart';
import 'package:macroaize/routes/directional_transition.dart';
import '../screens/onBording/onboarding_view.dart';
import 'app_routes.dart';
import 'package:macroaize/Model/recipe.dart';
import 'package:macroaize/screens/RecipesScreen/recipe_detail_screen.dart';
import 'package:macroaize/screens/EmailVerificationScreen/email_verification_view.dart';
import 'package:macroaize/screens/EmailVerificationScreen/email_verification_binding.dart';
import 'package:macroaize/screens/WorkoutScreen/workout_view.dart';
import 'package:macroaize/screens/WorkoutScreen/workout_binding.dart';
import 'package:macroaize/screens/DailyStreakScreen/daily_streak_view.dart';
import 'package:macroaize/screens/DailyStreakScreen/daily_streak_binding.dart';
import 'package:macroaize/screens/SettingScreen/notification_settings_view.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splashView;
  static const home = Routes.leadingView;

  static final routes = [
    GetPage(
      name: Paths.splashView,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Paths.welcomeView,
      page: () => const WelcomeView(),
      binding: WelcomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 600),
    ),
    GetPage(
      name: Paths.transitionView,
      page: () => const TransitionView(),
      binding: TransitionBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: Paths.accountDetailsView,
      page: () => const AccountDetailsView(),
    ),
    GetPage(
      name: Paths.planIntroView,
      page: () => const PlanIntroView(),
      binding: PlanIntroBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: Paths.onBoardingView,
      page: () => OnBoardingView(),
      binding: OnBoardingBinding(),
    ),
    GetPage(
      name: Paths.signUpView,
      page: () => SignUpView(),
      binding: SignUpBinding(),
      customTransition: DirectionalTransition(),
      popGesture: false, // iOS: child views use PopScope(canPop:false)
    ),
    GetPage(
      name: Paths.leadingView,
      page: () => LeadingView(),
      binding: LeadingBinding(),
      popGesture: false, // iOS: PopScope(canPop:false) on this route
    ),
    GetPage(
      name: Paths.homeView,
      page: () => HomeView(),
      binding: HomeBinding(),
      customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.scanFoodView,
      page: () => ScanFoodView(),
      binding: ScanFoodBinding(),
      customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.analyticsView,
      page: () => AnalyticsView(),
      binding: AnalyticsBinding(),
      customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.settingView,
      page: () => SettingView(),
      binding: SettingBinding(),
    ),
    GetPage(
      name: Paths.adjustGoalsView,
      page: () => AdjustGoalsView(),
      binding: AdjustGoalsBinding(),
    ),
    GetPage(
      name: Paths.personalDetailsView,
      page: () => PersonalDetailsView(),
      binding: PersonalDetailsBinding(),
      popGesture: false, // iOS: conditional canPop based on selectedView
    ),
    GetPage(
      name: Paths.scanCalorieView,
      page: () => ScanCalorieView(),
      binding: ScanCalorieBinding(),
      customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.historyView,
      page: () => HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: Paths.premiumView,
      page: () => PremiumView(),
      binding: PremiumBinding(),
      popGesture: false, // iOS: conditional canPop with delay
    ),
    GetPage(
      name: Paths.chatView,
      page: () => ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: Paths.chatHistoryView,
      page: () => ChatHistoryView(),
      binding: ChatHistoryBinding(),
    ),
    GetPage(
      name: Paths.withdrawalHistoryView,
      page: () => WithdrawalHistoryView(),
      binding: WithdrawalHistoryBinding(),
    ),
    GetPage(
      name: Paths.localFoodView,
      page: () => LocalFoodView(),
      binding: LocalFoodBinding(),
    ),
    GetPage(
      name: Paths.languageView,
      page: () => LanguageView(),
      binding: LanguageBinding(),
    ),
    GetPage(
      name: Paths.recipesView,
      page: () => const RecipesView(),
      binding: RecipesBinding(),
      customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.recipeDetailView,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final recipe =
            args != null && args['recipe'] is Recipe
                ? args['recipe'] as Recipe
                : null;
        if (recipe == null) return const RecipesView();
        return RecipeDetailScreen(recipe: recipe);
      },
    ),
    GetPage(
      name: Paths.emailVerificationView,
      page: () => const EmailVerificationView(),
      binding: EmailVerificationBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Paths.workoutView,
      page: () => const WorkoutView(),
      binding: WorkoutBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Paths.dailyStreakView,
      page: () => const DailyStreakView(),
      binding: DailyStreakBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Paths.notificationSettingsView,
      page: () => const NotificationSettingsView(),
      transition: Transition.rightToLeft,
    ),
  ];
}
