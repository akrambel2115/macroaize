import 'package:macroaize/screens/AdjustGoals/AdjustGoalsBinding.dart';
import 'package:macroaize/screens/AdjustGoals/AdjustGoalsView.dart';
import 'package:macroaize/screens/AnalyticsScreen/AnalyticsBinding.dart';
import 'package:macroaize/screens/AnalyticsScreen/AnalyticsView.dart';
import 'package:macroaize/screens/ChatHistoryScreen/ChatHistoryBinding.dart';
import 'package:macroaize/screens/ChatHistoryScreen/ChatHistoryView.dart';
import 'package:macroaize/screens/ChatScreen/ChatBinding.dart';
import 'package:macroaize/screens/ChatScreen/ChatView.dart';
import 'package:macroaize/screens/HomeScreen/HomeBinding.dart';
import 'package:macroaize/screens/HomeScreen/HomeView.dart';
import 'package:macroaize/screens/LocalFoodScreen/LocalFoodBinding.dart';
import 'package:macroaize/screens/LocalFoodScreen/LocalFoodView.dart';
import 'package:macroaize/screens/PersonalDetailsScreen/PersonalDetailsBinding.dart';
import 'package:macroaize/screens/PersonalDetailsScreen/PersonalDetailsView.dart';
import 'package:macroaize/screens/PremiumScreen/PremiumBinding.dart';
import 'package:macroaize/screens/PremiumScreen/PremiumView.dart';
import 'package:macroaize/screens/RecipesScreen/RecipesBinding.dart';
import 'package:macroaize/screens/RecipesScreen/RecipesView.dart';
import 'package:macroaize/screens/ScanCalorieScreen/ScanCalorieBinding.dart';
import 'package:macroaize/screens/ScanCalorieScreen/ScanCalorieView.dart';
import 'package:macroaize/screens/ScanFoodView/ScanFoodBinding.dart';
import 'package:macroaize/screens/ScanFoodView/ScanFoodView.dart';
import 'package:macroaize/screens/SettingScreen/SettingBinding.dart';
import 'package:macroaize/screens/SettingScreen/SettingView.dart';
import 'package:macroaize/screens/SignUpScreens/SingUpBinding.dart';
import 'package:macroaize/screens/SignUpScreens/SingUpView.dart';
import 'package:macroaize/screens/historyScreen/HistoryBinding.dart';
import 'package:macroaize/screens/historyScreen/HistoryView.dart';
import 'package:macroaize/screens/languageScreen/languageBinding.dart';
import 'package:macroaize/screens/languageScreen/languageView.dart';
import 'package:macroaize/screens/leadingScreen/LeadingBinding.dart';
import 'package:macroaize/screens/leadingScreen/LeadingView.dart';
import 'package:macroaize/screens/onBording/OnBoardingBinding.dart';
import 'package:macroaize/screens/splash/SplashBinding.dart';
import 'package:macroaize/screens/splash/SplashView.dart';
import 'package:macroaize/screens/welcome/WelcomeBinding.dart';
import 'package:macroaize/screens/welcome/WelcomeView.dart';
import 'package:macroaize/screens/planIntro/PlanIntroBinding.dart';
import 'package:macroaize/screens/planIntro/PlanIntroView.dart';
import 'package:macroaize/screens/transition/TransitionBinding.dart';
import 'package:macroaize/screens/transition/TransitionView.dart';
import 'package:macroaize/screens/WithdrawalHistoryScreen/WithdrawalHistoryBinding.dart';
import 'package:macroaize/screens/WithdrawalHistoryScreen/WithdrawalHistoryView.dart';
import 'package:get/get.dart';
import 'package:macroaize/screens/AccountDetails/AccountDetailsView.dart';
import 'package:macroaize/routes/directional_transition.dart';
import '../screens/onBording/OnBoardingView.dart';
import 'app_routes.dart';
import 'package:macroaize/Model/Recipe.dart';
import 'package:macroaize/screens/RecipesScreen/RecipeDetailScreen.dart';
import 'package:macroaize/screens/EmailVerificationScreen/EmailVerificationView.dart';
import 'package:macroaize/screens/EmailVerificationScreen/EmailVerificationBinding.dart';
import 'package:macroaize/screens/WorkoutScreen/WorkoutView.dart';
import 'package:macroaize/screens/WorkoutScreen/WorkoutBinding.dart';
import 'package:macroaize/screens/DailyStreakScreen/DailyStreakView.dart';
import 'package:macroaize/screens/DailyStreakScreen/DailyStreakBinding.dart';
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
    ),
    GetPage(
      name: Paths.leadingView,
      page: () => LeadingView(),
      binding: LeadingBinding(),
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
