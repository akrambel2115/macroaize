import 'package:get/get.dart';
import 'WithdrawalHistoryController.dart';

class WithdrawalHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WithdrawalHistoryController>(
      () => WithdrawalHistoryController(),
    );
  }
}
