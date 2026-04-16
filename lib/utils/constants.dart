/// Application constants
class Constants {
  // API URLs (base)
  static const String _baseUrl = 'https://boldrocchi.zwillinglabs.com';
  static const String loginUrl = '$_baseUrl/cardlogin';
  static const String regularLoginUrl = '$_baseUrl/login';
  static const String cardLoginApiUrl = '$_baseUrl/api/card/login';
  static const String userCardsAssignApiUrl = '$_baseUrl/api/userCards/assign';
  static const String orderListUrl = '$_baseUrl/orderlist';
  

  // Register screen access
  // IMPORTANT: This is only the initial fallback password.
  // The active password is stored securely on-device and can be changed in-app.
  static const String defaultRegisterPassword = 'boldrocchi@zwill2025';
  static const String registerPasswordKey = 'register_password';

  // SharedPreferences keys
  static const String tokenKey = 'auth_token';
  static const String cardUidKey = 'card_uid';
  static const String sessionCookieKey = 'session_cookie';
  
  // Assets
  static const String zwillingLogoAsset = 'assets/images/zwilling_logo.png';

  // NFC Configuration
  static const Duration nfcTimeout = Duration(seconds: 30);
  
  // HID RFID Configuration
  static const Duration hidDebounceDuration = Duration(milliseconds: 100);
  static const int maxUidLength = 20;
}

