class Session {
  static final Session _instance = Session._internal();
  factory Session() => _instance;
  Session._internal();

  String currentUsername = '';
}