// DEPRECATED: App-wide constants should come from AppConfigService/getAppConfig
// Kept for backward compatibility during migration. Avoid adding secrets here.

/// APP NAME FIRST
const appName = 'macroAize';

/// OpenRouter API key
/// Move this to a secure source; kept as empty placeholder.
String apiKey = '';

/// AI Model Configuration (use AppConfigService.aiModel instead)
const String aiModel = "google/gemini-2.5-flash-image-preview:free";

/// USDA FoodData Central API Key placeholder (do not ship real key)
const String usdaApiKey = '';

/// SHARE URLS (use AppConfigService)
const shareAppsAndroid = "";
const shareAppsIOS = "";

/// Policy links (use AppConfigService)
const String termsLink = '';
const String privacyLink = '';

/// In-app purchase IDs (use AppConfigService)
const androidInAppPurchaseIdWeekly = "";
const androidInAppPurchaseIdMonthly = "";
const androidInAppPurchaseIdYearly = "";

const iOSInAppPurchaseIdWeekly = "";
const iOSInAppPurchaseIdMonthly = "";
const iOSInAppPurchaseIdYearly = "";


