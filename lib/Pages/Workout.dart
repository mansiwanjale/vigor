import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Workout/workout_home.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fitness_center, size: 100, color: Colors.blueGrey),
            SizedBox(height: 20),
            Text(
              "Workout",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Add user details, settings, or logout button here
          ],
        ),
      ),
    );
  }
}

