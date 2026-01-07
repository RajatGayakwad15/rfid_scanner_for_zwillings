/// Application constants
class Constants {
  // API URLs
  static const String loginUrl = 'http://10.185.151.222:5000/cardlogin';
  static const String cardLoginApiUrl = 'http://10.185.151.222:5000/api/card/login';
  static const String orderListUrl = 'http://10.185.151.222:5000/list/process';
  


  // SharedPreferences keys
  static const String tokenKey = 'auth_token';
  static const String cardUidKey = 'card_uid';
  static const String sessionCookieKey = 'session_cookie';
  
  // NFC Configuration
  static const Duration nfcTimeout = Duration(seconds: 30);
  
  // HID RFID Configuration
  static const Duration hidDebounceDuration = Duration(milliseconds: 100);
  static const int maxUidLength = 20;
}

