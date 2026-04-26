import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String? _username;

  // SAVE USER (called after login)
  static Future<void> setUser(String username) async {
    _username = username;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // LOAD USER (called in main)
  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username');
  }

  // GET USER anywhere
  static String? getUser() {
    return _username;
  }
}
