import 'package:get/get.dart';
import '../LanguageJson/Arabic.dart';
import '../LanguageJson/Dutch.dart';
import '../LanguageJson/English.dart';
import '../LanguageJson/French.dart';
import '../LanguageJson/German.dart';
import '../LanguageJson/Hindi.dart';
import '../LanguageJson/Indonesia.dart';
import '../LanguageJson/Italian.dart';
import '../LanguageJson/Japanese.dart';
import '../LanguageJson/Polish.dart';
import '../LanguageJson/Portugal.dart';
import '../LanguageJson/Russian.dart';
import '../LanguageJson/Spanish.dart';
import '../LanguageJson/chinese.dart';
import '../LanguageJson/turkish.dart';

class LocalString extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US':  english,
    'japa_JAPA': japanese,
    'turk_TURK': turkish,
    'polish_POLISH': polish,
    'ity_ITY': italian,
    'dutch_DUTCH': dutch,
    'indo_INDO': indonesia,
    'por_PORTU': portugal,
    'ar_AR': arabic,
    'hi_IN': hindi,
    'russ_RUSS': russian,
    'ch_CH': chinese,
    'gem_GEM': german,
    'fre_FRE': french,
    'sp_SP': spanish
  };
}
