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

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      title: map["title"] ?? "",
      category: map["category"] ?? "",
      // Use int.tryParse to safely handle Strings from Firestore
      duration: int.tryParse(map["duration"].toString()) ?? 0,
      calories: int.tryParse(map["calories"].toString()) ?? 0,
      image: map["image"] ?? "",
    );
  }

}
