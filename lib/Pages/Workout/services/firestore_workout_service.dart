import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';
import '../../../utils/session.dart';

class FirestoreWorkoutService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Fetch all workout programs
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    try {
      final snapshot =
      await _firestore.collection('workouts').get();

      return snapshot.docs
          .map((doc) =>
      doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching workouts: $e');
      return [];
    }
  }

  /// Save completed workout to history
  Future<void> saveWorkout(
      WorkoutModel workout) async {
    try {
      await _firestore
          .collection('workout_history')
          .add({
        ...workout.toMap(),

        // User link
        "username": Session.getUser(),

        // Timestamp
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving workout: $e');
    }
  }

  /// Delete all workouts (use only during development)
  Future<void> deleteAllWorkouts() async {
    try {
      final snapshot =
      await _firestore.collection('workouts').get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('All workouts deleted');
    } catch (e) {
      print('Error deleting workouts: $e');
    }
  }

  /// Delete all workout history
  Future<void> deleteWorkoutHistory() async {
    try {
      final snapshot = await _firestore
          .collection('workout_history')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('Workout history deleted');
    } catch (e) {
      print('Error deleting history: $e');
    }
  }

  /// Check if workouts already exist
  Future<bool> workoutsExist() async {
    try {
      final snapshot = await _firestore
          .collection('workouts')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking workouts: $e');
      return false;
    }
  }
}