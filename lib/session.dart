import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static final Session _instance = Session._internal();
  factory Session() => _instance;
  Session._internal();

  String? currentUsername;

  // Persist the user so it stays logged in after restart
  static Future<void> setUser(String username) async {
    Session().currentUsername = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  // Load the user from storage into the singleton
  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    Session().currentUsername = prefs.getString('username');
  }

  // Static helper to get the user easily
  static String? getUser() => Session().currentUsername;
}
