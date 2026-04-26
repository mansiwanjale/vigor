import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_workout_service.dart';
import 'widgets/progress_ring.dart';
import 'workout_history.dart';
import 'active_workout.dart';
import 'models/workout_model.dart';
import '../../utils/session.dart';
import 'widgets/workout_chart.dart';


class WorkoutHome extends StatelessWidget {
  const WorkoutHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workout_history')
              .where('username', isEqualTo: Session.getUser())
              .snapshots(),
          builder: (context, snapshot) {
            int totalCalories = 0;
            int totalDuration = 0;
            int totalWorkouts = 0;

            Map<String, dynamic>? lastWorkout;

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;

              totalWorkouts = docs.length;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;

                totalCalories += (data['calories'] ?? 0) as int;
                totalDuration += (data['duration'] ?? 0) as int;
              }

              if (docs.isNotEmpty) {
                docs.sort((a, b) {
                  final aTime = a['timestamp'] as Timestamp?;
                  final bTime = b['timestamp'] as Timestamp?;

                  if (aTime == null || bTime == null) return 0;

                  return bTime.compareTo(aTime);
                });

                lastWorkout =
                docs.first.data() as Map<String, dynamic>;
              }
            }

            int weeklyGoalMinutes = 150;

            double weeklyProgress =
            totalDuration == 0
                ? 0
                : (totalDuration / 60) /
                weeklyGoalMinutes;

            if (weeklyProgress > 1) {
              weeklyProgress = 1;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hello ${Session.getUser()} 👋',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const WorkoutHistory(),
                            ),
                          );
                        },
                        icon:
                        const Icon(Icons.history, size: 30),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade800,
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weekly Goal',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${(totalDuration / 60).floor()} / $weeklyGoalMinutes mins',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Stay consistent 🔥',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ProgressRing(
                          progress: weeklyProgress,
                          label: 'Goal',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Quick Stats',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: statCard(
                          'Calories',
                          '$totalCalories',
                          Icons.local_fire_department,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: statCard(
                          'Workouts',
                          '$totalWorkouts',
                          Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: statCard(
                          'Minutes',
                          '${(totalDuration / 60).floor()}',
                          Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: statCard(
                          'Goal',
                          '${(weeklyProgress * 100).toInt()}%',
                          Icons.bolt,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const WorkoutChart(),

                  const SizedBox(height: 28),

                  if (lastWorkout != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Last Workout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            lastWorkout['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(lastWorkout['duration'] / 60).floor()} min • ${lastWorkout['calories']} kcal',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 34),

                  const Text(
                    'Workout Programs',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future:
                    FirestoreWorkoutService().getWorkouts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child:
                          CircularProgressIndicator(),
                        );
                      }

                      final workouts = snapshot.data!;

                      return ListView.builder(
                        physics:
                        const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          final workout = workouts[index];

                          final workoutModel = WorkoutModel(
                            title: workout['title'] ?? '',
                            category:
                            workout['category'] ?? '',
                            duration:
                            workout['duration'] ?? 0,
                            calories:
                            workout['calories'] ?? 0,
                            image:
                            workout['image'] ?? '',
                          );

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActiveWorkout(
                                    workout: workoutModel,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin:
                              const EdgeInsets.only(
                                bottom: 22,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(28),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                    const BorderRadius.only(
                                      topLeft:
                                      Radius.circular(28),
                                      topRight:
                                      Radius.circular(28),
                                    ),
                                    child: Image.network(
                                      workout['image'] ?? '',
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) {
                                        return Container(
                                          height: 180,
                                          color: Colors.black12,
                                        );
                                      },
                                    ),
                                  ),

                                  Padding(
                                    padding:
                                    const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workout['title'] ?? '',
                                          style:
                                          const TextStyle(
                                            fontSize: 22,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          workout['category'] ?? '',
                                          style: TextStyle(
                                            color: Colors
                                                .grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.timer,
                                              size: 18,
                                            ),
                                            const SizedBox(
                                                width: 8),
                                            Text(
                                              '${(workout['duration'] ?? 0) ~/ 60} min',
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons
                                                  .local_fire_department,
                                              color:
                                              Colors.orange,
                                              size: 18,
                                            ),
                                            const SizedBox(
                                                width: 8),
                                            Text(
                                              '${workout['calories']} kcal',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget statCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.deepPurple,
            size: 28,
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}