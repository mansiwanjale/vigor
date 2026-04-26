import 'package:flutter/material.dart';
import 'active_workout.dart';
import 'models/workout_model.dart';

class ExerciseDetail extends StatelessWidget {
  final WorkoutModel workout;

  const ExerciseDetail({
    Key? key,
    required this.workout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  workout.image,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                Positioned(
                  top: 50,
                  left: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    workout.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      infoCard(
                        Icons.timer,
                        '${workout.duration ~/ 60} min',
                      ),
                      const SizedBox(width: 12),
                      infoCard(
                        Icons.local_fire_department,
                        '${workout.calories} kcal',
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Workout Description',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'This workout helps improve endurance, burn calories, and build strength while keeping your body active.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.7,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Benefits',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  benefit('🔥 Burns calories'),
                  benefit('💪 Builds strength'),
                  benefit('❤️ Improves endurance'),
                  benefit('⚡ Boosts metabolism'),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActiveWorkout(
                              workout: workout,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.deepPurple,
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Start Workout',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoCard(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }
}