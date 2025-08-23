
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsBinding.dart';
import 'package:foodcalorietracker/screens/AdjustGoals/AdjustGoalsView.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsBinding.dart';
import 'package:foodcalorietracker/screens/AnalyticsScreen/AnalyticsView.dart';
import 'package:foodcalorietracker/screens/ChatHistoryScreen/ChatHistoryBinding.dart';
import 'package:foodcalorietracker/screens/ChatHistoryScreen/ChatHistoryView.dart';
import 'package:foodcalorietracker/screens/ChatScreen/ChatBinding.dart';
import 'package:foodcalorietracker/screens/ChatScreen/ChatView.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeBinding.dart';
import 'package:foodcalorietracker/screens/HomeScreen/HomeView.dart';
import 'package:foodcalorietracker/screens/LocalFoodScreen/LocalFoodBinding.dart';
import 'package:foodcalorietracker/screens/LocalFoodScreen/LocalFoodView.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsBinding.dart';
import 'package:foodcalorietracker/screens/PersonalDetailsScreen/PersonalDetailsView.dart';
import 'package:foodcalorietracker/screens/PremiumScreen/PremiumBinding.dart';
import 'package:foodcalorietracker/screens/PremiumScreen/PremiumView.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesBinding.dart';
import 'package:foodcalorietracker/screens/RecipesScreen/RecipesView.dart';
import 'package:foodcalorietracker/screens/ScanCalorieScreen/ScanCalorieBinding.dart';
import 'package:foodcalorietracker/screens/ScanCalorieScreen/ScanCalorieView.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodBinding.dart';
import 'package:foodcalorietracker/screens/ScanFoodView/ScanFoodView.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingBinding.dart';
import 'package:foodcalorietracker/screens/SettingScreen/SettingView.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SingUpBinding.dart';
import 'package:foodcalorietracker/screens/SignUpScreens/SingUpView.dart';
import 'package:foodcalorietracker/screens/historyScreen/HistoryBinding.dart';
import 'package:foodcalorietracker/screens/historyScreen/HistoryView.dart';
import 'package:foodcalorietracker/screens/languageScreen/languageBinding.dart';
import 'package:foodcalorietracker/screens/languageScreen/languageView.dart';
import 'package:foodcalorietracker/screens/leadingScreen/LeadingBinding.dart';
import 'package:foodcalorietracker/screens/leadingScreen/LeadingView.dart';
import 'package:foodcalorietracker/screens/onBording/OnBoardingBinding.dart';
import 'package:foodcalorietracker/screens/splash/SplashBinding.dart';
import 'package:foodcalorietracker/screens/splash/SplashView.dart';
import 'package:foodcalorietracker/screens/welcome/WelcomeBinding.dart';
import 'package:foodcalorietracker/screens/welcome/WelcomeView.dart';
import 'package:foodcalorietracker/screens/planIntro/PlanIntroBinding.dart';
import 'package:foodcalorietracker/screens/planIntro/PlanIntroView.dart';
import 'package:foodcalorietracker/screens/transition/TransitionBinding.dart';
import 'package:foodcalorietracker/screens/transition/TransitionView.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/routes/directional_transition.dart';
import '../screens/onBording/OnBoardingView.dart';
import 'app_routes.dart';

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
      name: Paths.planIntroView,
      page: () => const PlanIntroView(),
      binding: PlanIntroBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: Paths.onBoardingView,
      page: () =>  OnBoardingView(),
      binding: OnBoardingBinding(),
    ),
    GetPage(
      name: Paths.signUpView,
      page: () =>  SignUpView(),
      binding: SignUpBinding(),
      customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.leadingView,
      page: () =>  LeadingView(),
      binding: LeadingBinding(),
    ),
    GetPage(
  name: Paths.homeView,
  page: () =>  HomeView(),
  binding: HomeBinding(),
  customTransition: DirectionalTransition(),
    ),
    GetPage(
  name: Paths.scanFoodView,
  page: () =>  ScanFoodView(),
  binding: ScanFoodBinding(),
  customTransition: DirectionalTransition(),
    ),
    GetPage(
  name: Paths.analyticsView,
  page: () =>  AnalyticsView(),
  binding: AnalyticsBinding(),
  customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.settingView,
      page: () =>  SettingView(),
      binding: SettingBinding(),
    ),
    GetPage(
      name: Paths.adjustGoalsView,
      page: () =>  AdjustGoalsView(),
      binding: AdjustGoalsBinding(),
    ),
    GetPage(
      name: Paths.personalDetailsView,
      page: () =>  PersonalDetailsView(),
      binding: PersonalDetailsBinding(),
    ),
    GetPage(
      name: Paths.scanCalorieView,
      page: () =>  ScanCalorieView(),
      binding: ScanCalorieBinding(),
      customTransition: DirectionalTransition(),
    ),
    GetPage(
      name: Paths.historyView,
      page: () =>  HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: Paths.premiumView,
      page: () =>  PremiumView(),
      binding: PremiumBinding(),
    ),
    GetPage(
      name: Paths.chatView,
      page: () =>  ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: Paths.chatHistoryView,
      page: () =>  ChatHistoryView(),
      binding: ChatHistoryBinding(),
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
  ];
}
