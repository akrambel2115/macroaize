import 'package:macroaize/screens/PersonalDetailsScreen/personal_details_controller.dart';
import 'package:get/get.dart';

class PersonalDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PersonalDetailsController());
  }
}
