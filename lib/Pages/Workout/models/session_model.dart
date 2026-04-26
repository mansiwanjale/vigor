class SessionModel {
  final String workoutName;
  final int duration;
  final int calories;
  final DateTime date;

  SessionModel({
    required this.workoutName,
    required this.duration,
    required this.calories,
    required this.date,
  });

  factory SessionModel.fromMap(Map<String, dynamic> data) {
    return SessionModel(
      workoutName: data['title'] ?? '',
      duration: data['duration'] ?? 0,
      calories: data['calories'] ?? 0,
      date: data['timestamp'].toDate(),
    );
  }
}