import 'package:macroaize/screens/PersonalDetailsScreen/PersonalDetailsController.dart';
import 'package:get/get.dart';

class PersonalDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PersonalDetailsController());
  }
}
