
import 'package:foodcalorietracker/screens/SignUpScreens/SignUpController.dart';
import 'package:get/get.dart';

class SignUpBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => SignUpController(),);
  }
}