import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';
import '../../../session.dart';

class FirestoreWorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Get UNIQUE workouts (no duplicates)
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    try {
      final snapshot = await _firestore.collection('workouts').get();

      final Map<String, Map<String, dynamic>> uniqueWorkouts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final workout = {
          "id": doc.id,
          "title": data["title"] ?? "Workout",
          "category": data["category"] ?? "general",
          "duration": data["duration"] ?? 0,
          "calories": data["calories"] ?? 0,
          "image": data["image"] ?? "",
        };

        /// 🔥 priority key = doc.id (best uniqueness)
        uniqueWorkouts[doc.id] = workout;

        /// 🔥 extra safety: also prevent same-title duplicates
        uniqueWorkouts[data["title"] ?? doc.id] = workout;
      }

      return uniqueWorkouts.values.toList();
    } catch (e) {
      print("❌ Workout fetch error: $e");
      return [];
    }
  }

  /// ✅ Save workout history
  Future<void> saveWorkout(WorkoutModel workout) async {
    final user = Session().currentUsername ?? "guest";

    await _firestore.collection('workout_history').add({
      ...workout.toMap(),
      "username": user,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  /// Check workouts exist
  Future<bool> workoutsExist() async {
    final snap = await _firestore.collection('workouts').limit(1).get();
    return snap.docs.isNotEmpty;
  }
}