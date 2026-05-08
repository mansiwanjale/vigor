import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';
import '../../../session.dart';

class FirestoreWorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Get UNIQUE workouts from Firestore
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    try {
      final snapshot = await _firestore.collection('workouts').get();
      final Map<String, Map<String, dynamic>> uniqueWorkouts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final workout = {
          "id": doc.id,
          "title": data["title"] ?? "Workout",
          "category": data["category"] ?? "General",
          "duration": data["duration"] ?? 0,
          "calories": data["calories"] ?? 0,
          "image": data["image"] ?? "",
          "sets": data["sets"] ?? 4,
          "icon": data["icon"] ?? "🏋️",
        };
        uniqueWorkouts[doc.id] = workout;
        uniqueWorkouts[data["title"] ?? doc.id] = workout;
      }

      return uniqueWorkouts.values.toList();
    } catch (e) {
      print("❌ Workout fetch error: $e");
      return [];
    }
  }

  /// ✅ Get exercises for a specific workout from subcollection
  Future<List<Map<String, dynamic>>> getExercisesForWorkout(
      String workoutId) async {
    try {
      final snapshot = await _firestore
          .collection('workouts')
          .doc(workoutId)
          .collection('exercises')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "name": data["name"] ?? "Exercise",
          "detail": data["detail"] ?? "",
          "icon": data["icon"] ?? "💪",
          "sets": data["sets"] ?? 3,
          "reps": data["reps"] ?? 10,
        };
      }).toList();
    } catch (e) {
      print("❌ Exercise fetch error: $e");
      return [];
    }
  }

  /// ✅ Get a random tip from Firestore tips collection
  Future<Map<String, String>> getTipOfDay() async {
    try {
      final snapshot = await _firestore.collection('tips').get();
      if (snapshot.docs.isEmpty) {
        return {
          'tip': 'Stay consistent — results come with time.',
          'icon': '💪'
        };
      }
      final day = DateTime.now().weekday - 1;
      final doc = snapshot.docs[day % snapshot.docs.length];
      final data = doc.data();
      return {
        'tip': data['tip'] ?? 'Stay consistent!',
        'icon': data['icon'] ?? '💪',
      };
    } catch (e) {
      print("❌ Tips fetch error: $e");
      return {
        'tip': 'Stay consistent — results come with time.',
        'icon': '💪'
      };
    }
  }

  /// ✅ Get exercise of the day from Firestore exercises collection
  Future<Map<String, dynamic>> getExerciseOfDay() async {
    try {
      final snapshot = await _firestore.collection('exercises').get();
      if (snapshot.docs.isEmpty) {
        return {
          'name': 'Push-Ups',
          'muscle': 'Chest · Triceps',
          'sets': '4 x 15',
          'icon': '🏋️'
        };
      }
      final day = DateTime.now().weekday - 1;
      final doc = snapshot.docs[day % snapshot.docs.length];
      final data = doc.data();
      return {
        'name': data['name'] ?? 'Push-Ups',
        'muscle': data['muscle'] ?? 'Full Body',
        'sets': data['sets'] ?? '4 x 15',
        'icon': data['icon'] ?? '🏋️',
      };
    } catch (e) {
      print("❌ Exercise of day fetch error: $e");
      return {
        'name': 'Push-Ups',
        'muscle': 'Chest · Triceps',
        'sets': '4 x 15',
        'icon': '🏋️'
      };
    }
  }

  /// ✅ Get weekly goal from user_profiles based on fitness goal
  Future<int> getWeeklyGoal(String username) async {
    try {
      final doc = await _firestore
          .collection('user_profiles')
          .doc(username)
          .get();

      if (!doc.exists) return 150;

      final data = doc.data()!;
      final String goal = (data['goal'] ?? '').toString().toLowerCase();

      if (goal.contains('weight loss') || goal.contains('lose')) return 200;
      if (goal.contains('muscle') || goal.contains('gain')) return 180;
      if (goal.contains('endurance') || goal.contains('cardio')) return 250;
      if (goal.contains('maintain')) return 120;
      if (goal.contains('flexibility') || goal.contains('yoga')) return 100;

      return 150;
    } catch (e) {
      print("❌ Weekly goal fetch error: $e");
      return 150;
    }
  }

  /// ✅ Save workout history with completedAt for streak & stats tracking
  Future<void> saveWorkout(WorkoutModel workout) async {
    final user = Session().currentUsername ?? "guest";
    await _firestore.collection('workout_history').add({
      ...workout.toMap(),
      "username": user,
      "timestamp": FieldValue.serverTimestamp(),
      "completedAt": Timestamp.now(), // ← fixes today/weekly/streak showing 0
    });
  }

  /// Check workouts exist
  Future<bool> workoutsExist() async {
    final snap = await _firestore.collection('workouts').limit(1).get();
    return snap.docs.isNotEmpty;
  }
}