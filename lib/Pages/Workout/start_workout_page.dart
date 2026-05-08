import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/workout_model.dart';
import 'active_workout.dart';
import '../../main.dart';

class StartWorkoutPage extends StatelessWidget {
  final WorkoutModel workout;

  const StartWorkoutPage({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> previewExercises = [
      {'name': 'Warm Up', 'detail': '5 min light cardio', 'icon': '🔥'},
      {'name': workout.category, 'detail': 'Main block', 'icon': '🏋️'},
      {'name': 'Core Finisher', 'detail': '3 x 20 reps', 'icon': '💪'},
      {'name': 'Cool Down', 'detail': '5 min stretching', 'icon': '🧘'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.card),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'WORKOUT DETAIL',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ── HERO CARD ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              workout.category.toUpperCase(),
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            workout.title,
                            style: GoogleFonts.bebasNeue(
                              fontSize: 42,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _heroStat(
                                Icons.timer_rounded,
                                '${(workout.duration / 60).floor()} min',
                                'Duration',
                              ),
                              const SizedBox(width: 24),
                              _heroStat(
                                Icons.local_fire_department_rounded,
                                '${workout.calories}',
                                'Calories',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── WHAT'S INSIDE ──
                    Text(
                      'WHAT\'S INSIDE',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...previewExercises.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ex = entry.value;
                      return _ExerciseRow(
                        number: i + 1,
                        name: ex['name'],
                        detail: ex['detail'],
                        icon: ex['icon'],
                        isLast: i == previewExercises.length - 1,
                      );
                    }),

                    const SizedBox(height: 28),

                    // ── QUICK TIPS ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border:
                        Border.all(color: AppColors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Have your water bottle ready. Focus on form over speed.',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── START BUTTON (pinned bottom) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveWorkout(workout: workout),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'START WORKOUT',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 22,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.bebasNeue(
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.barlowCondensed(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int number;
  final String name;
  final String detail;
  final String icon;
  final bool isLast;

  const _ExerciseRow({
    required this.number,
    required this.name,
    required this.detail,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 32,
                color: AppColors.card,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
