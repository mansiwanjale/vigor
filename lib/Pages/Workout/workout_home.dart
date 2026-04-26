import 'package:flutter/material.dart';
import 'data/dummy_workouts.dart';
import 'widgets/workout_card.dart';
import 'active_workout.dart';

class WorkoutHome extends StatelessWidget {
  const WorkoutHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Workout',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Choose your training session',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: ListView.builder(
                  itemCount: dummyWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = dummyWorkouts[index];

                    return WorkoutCard(
                      workout: workout,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveWorkout(
                              workout: workout,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}