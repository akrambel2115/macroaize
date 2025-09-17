import 'package:get/get.dart';
import 'package:foodcalorietracker/shared/models/influencer.dart';
import 'package:foodcalorietracker/shared/services/influencer_service.dart';

class WithdrawalHistoryController extends GetxController {
  static final _influencerService = InfluencerService();

  List<WithdrawalRecord> withdrawalHistory = [];
  bool isLoading = true;

  @override
  void onInit() {
    super.onInit();
    _loadWithdrawalHistory();
  }

  Future<void> _loadWithdrawalHistory() async {
    try {
      isLoading = true;
      update();

      final influencer = await _influencerService.getInfluencerOnce();
      if (influencer != null) {
        withdrawalHistory =
            influencer.withdrawHistory.reversed.toList(); // Show newest first
      }
    } catch (e) {
      print('Error loading withdrawal history: $e');
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> refreshHistory() async {
    await _loadWithdrawalHistory();
  }
}
