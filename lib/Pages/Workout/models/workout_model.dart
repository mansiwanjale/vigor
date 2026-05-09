import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutModel {
  final String title;
  final String category;
  final int duration;
  final int calories;
  final String image;
  final int sets;
  final String icon;

  WorkoutModel({
    required this.title,
    required this.category,
    required this.duration,
    required this.calories,
    required this.image,
    this.sets = 4,
    this.icon = '🏋️',
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "category": category,
      "duration": duration,
      "calories": calories,
      "image": image,
      "sets": sets,
      "icon": icon,
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      title: map["title"] ?? "",
      category: map["category"] ?? "",
      duration: int.tryParse(map["duration"].toString()) ?? 0,
      calories: int.tryParse(map["calories"].toString()) ?? 0,
      image: map["image"] ?? "",
      sets: int.tryParse(map["sets"].toString()) ?? 4,
      icon: map["icon"] ?? "🏋️",
    );
  }
}
