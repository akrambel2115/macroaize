import 'package:foodcalorietracker/screens/HomeScreen/HomeController.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings{
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => HomeController(),);
  }
}