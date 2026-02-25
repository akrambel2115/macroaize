import 'dart:convert';
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService extends GetxService {
  static const _cacheKey = 'app_config_cache_v1';
  static const _cacheTsKey = 'app_config_cache_updatedAt';

  final RxBool _loaded = false.obs;
  Map<String, dynamic> _config = const {};

  bool get isLoaded => _loaded.value;

  String get appName => (_config['app']?['name'] as String?) ?? 'macroAize';
  String get aiModel => (_config['aiModel'] as String?) ?? 'google/gemini-2.5-flash-image-preview:free';
  int get freeScanLimit => (_config['limits']?['scan'] as num?)?.toInt() ?? 2;
  int get freeChatLimit => (_config['limits']?['chat'] as num?)?.toInt() ?? 5;

  String get termsLink => (_config['links']?['terms'] as String?) ?? '';
  String get privacyLink => (_config['links']?['privacy'] as String?) ?? '';
  String get shareUrlAndroid => (_config['links']?['shareAndroid'] as String?) ?? '';
  String get shareUrlIos => (_config['links']?['shareIos'] as String?) ?? '';

  String get playStoreUrl => (_config['links']?['playStoreUrl'] as String?) ?? shareUrlAndroid;
  String get appStoreUrl => (_config['links']?['appStoreUrl'] as String?) ?? shareUrlIos;

  Map<String, String> get androidIapIds => {
        'weekly': (_config['iap']?['android']?['weekly'] as String?) ?? '',
        'monthly': (_config['iap']?['android']?['monthly'] as String?) ?? '',
        'yearly': (_config['iap']?['android']?['yearly'] as String?) ?? '',
      };
  Map<String, String> get iosIapIds => {
        'weekly': (_config['iap']?['ios']?['weekly'] as String?) ?? '',
        'monthly': (_config['iap']?['ios']?['monthly'] as String?) ?? '',
        'yearly': (_config['iap']?['ios']?['yearly'] as String?) ?? '',
      };

  int get premiumMonthlyPriceDzd => (_config['pricing']?['monthlyDzd'] as num?)?.toInt() ?? 450;
  int get premiumYearlyPriceDzd => (_config['pricing']?['yearlyDzd'] as num?)?.toInt() ?? 4500;

  bool get subscriptionsEnabled => (_config['features']?['subscriptionsEnabled'] as bool?) ?? true;

  String get minRequiredAppVersion => (_config['app']?['minRequiredVersion'] as String?) ?? '1.0.0';
  String get updateMessage => (_config['app']?['updateMessage'] as String?) ?? 'A new version is required to continue using MacroAize.';

  Future<AppConfigService> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        _config = map['config'] as Map<String, dynamic>? ?? {};
        _loaded.value = true;
      }
    } catch (_) {}

    unawaited(_refreshFromServer());
    return this;
  }

  Future<void> refresh() => _refreshFromServer(force: true);

  Future<void> _refreshFromServer({bool force = false}) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('getAppConfig');
      final result = await callable.call();
      final data = result.data as Map<dynamic, dynamic>?;
      if (data == null) return;

      final config = Map<String, dynamic>.from(data['config'] as Map);
      final updatedAt = (data['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

      _config = config;
      _loaded.value = true;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode({'config': _config, 'updatedAt': updatedAt}));
        await prefs.setInt(_cacheTsKey, updatedAt);
      } catch (_) {}
    } catch (_) {}
  }
}
