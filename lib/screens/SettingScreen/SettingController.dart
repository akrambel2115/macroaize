import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constant/Appkey.dart';

class SettingController extends GetxController{


  openPrivacy()
  async {
    final Uri url = Uri.parse(privacyLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  openTerms()
  async {
    final Uri url = Uri.parse(termsLink);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }


}