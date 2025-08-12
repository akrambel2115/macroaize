import 'package:get/get.dart';
import '../LanguageJson/Arabic.dart';
import '../LanguageJson/English.dart';
import '../LanguageJson/French.dart';

class LocalString extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // Arabic first (default + fallback)
    'ar_AR': arabic,
    'en_US':  english,
    'fre_FRE': french,
  };
}
