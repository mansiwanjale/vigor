import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/firestore_workout_service.dart';
import 'widgets/progress_ring.dart';
import 'workout_history.dart';
import 'active_workout.dart';
import 'models/workout_model.dart';
import '../../session.dart';
import 'widgets/workout_chart.dart';
import '../../main.dart';

class WorkoutHome extends StatefulWidget {
  const WorkoutHome({Key? key}) : super(key: key);

  @override
  State<WorkoutHome> createState() => _WorkoutHomeState();
}

class _WorkoutHomeState extends State<WorkoutHome> {
  late Future<List<Map<String, dynamic>>> _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _workoutsFuture = FirestoreWorkoutService().getWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    final username = Session().currentUsername;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workout_history')
              .where('username', isEqualTo: username)
              .snapshots(),
          builder: (context, snapshot) {

            int totalCalories = 0;
            int totalDuration = 0;
            int totalWorkouts = 0;

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;

              totalWorkouts = docs.length;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;

                totalCalories += (data['calories'] as num? ?? 0).toInt();
                totalDuration += (data['duration'] as num? ?? 0).toInt();
              }
            }

            double weeklyProgress = (totalDuration / 60) / 150;
            if (weeklyProgress > 1.0) weeklyProgress = 1.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Greeting ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good morning',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${username ?? "User"} 👋',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkoutHistory(),
                          ),
                        ),
                        icon: const Icon(Icons.history_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Progress Card ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Weekly Progress',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${(totalDuration / 60).floor()} / 150 min',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ProgressRing(
                          progress: weeklyProgress,
                          label: '${(weeklyProgress * 100).toInt()}%',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Stats ──
                  Row(
                    children: [
                      _smallStat('Calories', '$totalCalories',
                          Icons.local_fire_department, Colors.orange),
                      const SizedBox(width: 12),
                      _smallStat('Workouts', '$totalWorkouts',
                          Icons.fitness_center, AppColors.green),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const WorkoutChart(),

                  const SizedBox(height: 32),

                  const Text(
                    'Available Workouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── WORKOUT LIST (DEDUPED) ──
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _workoutsFuture,
                    builder: (context, workoutSnap) {
                      if (workoutSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.green,
                          ),
                        );
                      }

                      final workouts = workoutSnap.data ?? [];

                      // ✅ REMOVE DUPLICATES (by title)
                      final Map<String, Map<String, dynamic>> uniqueMap = {};
                      for (var w in workouts) {
                        uniqueMap[w['title']] = w;
                      }
                      final uniqueWorkouts = uniqueMap.values.toList();

                      if (uniqueWorkouts.isEmpty) {
                        return const Center(
                          child: Text("No workouts available"),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: uniqueWorkouts.length,
                        itemBuilder: (context, index) {
                          final workout = uniqueWorkouts[index];
                          final model = WorkoutModel.fromMap(workout);

                          return _SimpleWorkoutCard(
                            workout: model,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ActiveWorkout(workout: model),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _smallStat(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleWorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;

  const _SimpleWorkoutCard({
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 🏋️ + ✋ icon combo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "🏋️✋",
                style: TextStyle(fontSize: 20),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(workout.duration / 60).floor()} min  •  ${workout.calories} kcal',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}