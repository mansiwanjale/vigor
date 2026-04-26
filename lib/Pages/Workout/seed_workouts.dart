import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedWorkouts() async {
  final db = FirebaseFirestore.instance;

  final workouts = [
    {
      "title": "Cardio Blast",
      "category": "cardio",
      "duration": 300,
      "calories": 60,
      "image": ""
    },
    {
      "title": "Morning Run",
      "category": "cardio",
      "duration": 420,
      "calories": 90,
      "image": ""
    },
    {
      "title": "Jump Rope Rush",
      "category": "cardio",
      "duration": 240,
      "calories": 70,
      "image": ""
    },
    {
      "title": "Fat Burner HIIT",
      "category": "hiit",
      "duration": 300,
      "calories": 110,
      "image": ""
    },
    {
      "title": "Sweat Session",
      "category": "hiit",
      "duration": 270,
      "calories": 95,
      "image": ""
    },
    {
      "title": "Push Power",
      "category": "strength",
      "duration": 240,
      "calories": 55,
      "image": ""
    },
    {
      "title": "Upper Body Smash",
      "category": "strength",
      "duration": 300,
      "calories": 75,
      "image": ""
    },
    {
      "title": "Chest Builder",
      "category": "strength",
      "duration": 280,
      "calories": 68,
      "image": ""
    },
    {
      "title": "Leg Day Strong",
      "category": "strength",
      "duration": 330,
      "calories": 82,
      "image": ""
    },
    {
      "title": "Core Strength",
      "category": "strength",
      "duration": 260,
      "calories": 61,
      "image": ""
    },
    {
      "title": "Abs Burner",
      "category": "abs",
      "duration": 180,
      "calories": 45,
      "image": ""
    },
    {
      "title": "Six Pack Attack",
      "category": "abs",
      "duration": 240,
      "calories": 55,
      "image": ""
    },
    {
      "title": "Crunch Time",
      "category": "abs",
      "duration": 210,
      "calories": 48,
      "image": ""
    },
    {
      "title": "Plank Master",
      "category": "abs",
      "duration": 300,
      "calories": 62,
      "image": ""
    },
    {
      "title": "Sunrise Yoga",
      "category": "yoga",
      "duration": 420,
      "calories": 40,
      "image": ""
    },
    {
      "title": "Stress Relief Flow",
      "category": "yoga",
      "duration": 480,
      "calories": 42,
      "image": ""
    },
    {
      "title": "Flexibility Boost",
      "category": "yoga",
      "duration": 360,
      "calories": 38,
      "image": ""
    },
    {
      "title": "Full Body Burn",
      "category": "workout",
      "duration": 360,
      "calories": 75,
      "image": ""
    },
    {
      "title": "Power Circuit",
      "category": "workout",
      "duration": 420,
      "calories": 88,
      "image": ""
    },
    {
      "title": "Beginner Burn",
      "category": "workout",
      "duration": 240,
      "calories": 52,
      "image": ""
    },
  ];

  for (var workout in workouts) {
    await db.collection('workouts').add(workout);
  }

  print("20 Premium Workouts Added Successfully");
}