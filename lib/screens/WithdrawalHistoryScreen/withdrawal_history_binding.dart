import 'package:get/get.dart';
import 'withdrawal_history_controller.dart';

class WithdrawalHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WithdrawalHistoryController>(
      () => WithdrawalHistoryController(),
    );
  }
}
