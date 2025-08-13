import 'package:get/get.dart';
import '../LanguageJson/Arabic.dart';
import '../LanguageJson/English.dart';
import '../LanguageJson/French.dart';

class LocalString extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
  // Support common locale variants for robustness
  'ar_SA': arabic,
  'ar': arabic,
  'en_US': english,
  'en': english,
  'fr_FR': french,
  'fr': french,
  };
}
