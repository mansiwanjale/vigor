import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutModel {
  final String title;
  final String category;
  final int duration;
  final int calories;
  final String image;

  WorkoutModel({
    required this.title,
    required this.category,
    required this.duration,
    required this.calories,
    required this.image,
  });

  // 👉 Used ONLY for workout programs (seeded ones)
  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "category": category,
      "duration": duration,
      "calories": calories,
      "image": image,
    };
  }

  // 👉 Used when reading from Firebase
  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      title: map["title"] ?? "",
      category: map["category"] ?? "",
      duration: map["duration"] ?? 0,
      calories: map["calories"] ?? 0,
      image: map["image"] ?? "",
    );
  }
}
