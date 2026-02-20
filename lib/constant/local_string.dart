import 'package:get/get.dart';
import '../LanguageJson/arabic.dart';
import '../LanguageJson/english.dart';
import '../LanguageJson/french.dart';

class LocalString extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {

  'ar_SA': arabic,
  'ar': arabic,
  'en_US': english,
  'en': english,
  'fr_FR': french,
  'fr': french,
  };
}
