import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Service for handling API calls
class ApiService {
  /// Login with RFID card UID.
  /// Logs full request/response so you can see it in `flutter run` / Logcat
  /// and stores the session cookie from the `Set-Cookie` header.
  static Future<Map<String, dynamic>?> cardLogin(String cardUid) async {
    try {
      // Log outgoing request
      print(
          '[ApiService] -> POST ${Constants.cardLoginApiUrl}  body: {\"uid\": \"$cardUid\"}');

      final response = await http
          .post(
            Uri.parse(Constants.cardLoginApiUrl),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, String>{'uid': cardUid}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[ApiService] !! cardLogin TIMEOUT after 10s');
              throw Exception('Request timeout');
            },
          );

      // Log raw HTTP response
      print(
          '[ApiService] <- status: ${response.statusCode}, headers: ${response.headers}');
      print('[ApiService] <- body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        // Extract and store session cookie from Set-Cookie header
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null && setCookieHeader.isNotEmpty) {
          final match =
              RegExp(r'([^=;]+)=([^;]+)').firstMatch(setCookieHeader);
          if (match != null) {
            final name = match.group(1)!.trim();
            final value = match.group(2)!.trim();
            final fullCookie = '$name=$value';

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(Constants.sessionCookieKey, fullCookie);
            print('[ApiService] saved session cookie: $fullCookie');
          } else {
            print(
                '[ApiService] WARNING: could not parse Set-Cookie header: $setCookieHeader');
          }
        } else {
          print('[ApiService] No Set-Cookie header received from server');
        }

        print(
            '[ApiService] cardLogin SUCCESS (status ${response.statusCode}) payload: $responseData');
        return responseData;
      } else {
        print(
            '[ApiService] cardLogin FAILED (status ${response.statusCode}) body: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('[ApiService] cardLogin ERROR: $e');
      print('[ApiService] StackTrace: $stack');
      return null;
    }
  }
  
  /// Get stored session cookie (also logged so you can verify it).
  static Future<String?> getSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(Constants.sessionCookieKey);
    print('[ApiService] loaded session cookie from storage: ${cookie ?? 'null'}');
    return cookie;
  }

  /// Assign card to user. POST /api/userCards/assign
  /// Request: { "userId": 123, "cardUid": "A1B2C3D4" }
  /// Response: { "success": true, "message": "...", "data": {...} }
  static Future<Map<String, dynamic>?> assignUserCard(int userId, String cardUid) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'cardUid': cardUid,
      };
      print('[ApiService] -> POST ${Constants.userCardsAssignApiUrl} body: $body');

      final response = await http
          .post(
            Uri.parse(Constants.userCardsAssignApiUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('[ApiService] !! assignUserCard TIMEOUT after 10s');
              throw Exception('Request timeout');
            },
          );

      print('[ApiService] <- status: ${response.statusCode} body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[ApiService] assignUserCard SUCCESS: $data');
        return data;
      }
      print('[ApiService] assignUserCard FAILED: ${response.body}');
      return null;
    } catch (e, stack) {
      print('[ApiService] assignUserCard ERROR: $e');
      print('[ApiService] StackTrace: $stack');
      return null;
    }
  }
}

