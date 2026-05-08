import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/firestore_workout_service.dart';
import 'widgets/progress_ring.dart';
import 'workout_history.dart';
import 'start_workout_page.dart';
import 'models/workout_model.dart';
import '../../session.dart';
import '../../main.dart';

// ─────────────────────────────────────────
// GOAL CALCULATOR — history-based with WHO fallback
// ─────────────────────────────────────────
int calculateWeeklyGoal({
  required List<QueryDocumentSnapshot> docs,
  required int? userSetGoal,
}) {
  // If user manually set a goal, always respect it
  if (userSetGoal != null && userSetGoal > 0) return userSetGoal;

  final now = DateTime.now();
  final fourWeeksAgo = now.subtract(const Duration(days: 28));

  // Collect weekly minute totals for last 4 weeks
  // weekIndex: 0 = this week, 1 = last week, 2 = two weeks ago, 3 = three weeks ago
  final Map<int, int> weeklyMinutes = {};

  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['completedAt'] == null) continue;

    final completedAt = (data['completedAt'] as Timestamp).toDate();
    if (completedAt.isBefore(fourWeeksAgo)) continue;

    final duration = (data['duration'] as num? ?? 0).toInt();
    final daysAgo = now.difference(completedAt).inDays;
    final weekIndex = daysAgo ~/ 7;

    weeklyMinutes[weekIndex] =
        (weeklyMinutes[weekIndex] ?? 0) + (duration ~/ 60);
  }

  // Not enough history — fall back to WHO baseline of 150 min
  if (weeklyMinutes.length < 2) return 150;

  // Average the weeks we have data for
  final avg =
      weeklyMinutes.values.reduce((a, b) => a + b) / weeklyMinutes.length;

  // Add 10% progressive overload and round to nearest 5
  final goal = (avg * 1.1 / 5).round() * 5;

  // Clamp between 150 (WHO minimum) and 600 (reasonable upper limit)
  return goal.clamp(150, 600);
}

class WorkoutHome extends StatefulWidget {
  const WorkoutHome({Key? key}) : super(key: key);

  @override
  State<WorkoutHome> createState() => _WorkoutHomeState();
}

class _WorkoutHomeState extends State<WorkoutHome> {
  late Future<List<Map<String, dynamic>>> _workoutsFuture;
  int? _userSetGoal;

  final List<Map<String, String>> _tips = [
    {'tip': 'Drink water before, during, and after your workout.', 'icon': '💧'},
    {'tip': 'Warm up for 5 minutes before any intense session.', 'icon': '🔥'},
    {'tip': 'Rest days are part of the plan — your muscles grow then.', 'icon': '😴'},
    {'tip': 'Track your reps — small progress adds up fast.', 'icon': '📈'},
    {'tip': 'Consistency beats intensity every single time.', 'icon': '💪'},
  ];

  final List<Map<String, dynamic>> _exerciseOfDay = [
    {'name': 'Push-Ups', 'muscle': 'Chest · Triceps', 'sets': '4 x 15', 'icon': '🏋️'},
    {'name': 'Squats', 'muscle': 'Quads · Glutes', 'sets': '4 x 20', 'icon': '🦵'},
    {'name': 'Plank', 'muscle': 'Core · Shoulders', 'sets': '3 x 45s', 'icon': '🧘'},
    {'name': 'Pull-Ups', 'muscle': 'Back · Biceps', 'sets': '3 x 10', 'icon': '💪'},
    {'name': 'Burpees', 'muscle': 'Full Body', 'sets': '3 x 12', 'icon': '⚡'},
  ];

  late Map<String, String> _todayTip;
  late Map<String, dynamic> _todayExercise;

  @override
  void initState() {
    super.initState();
    _workoutsFuture = FirestoreWorkoutService().getWorkouts();
    final day = DateTime.now().weekday - 1;
    _todayTip = _tips[day % _tips.length];
    _todayExercise = _exerciseOfDay[day % _exerciseOfDay.length];
    _loadUserGoal();
  }

  Future<void> _loadUserGoal() async {
    final username = Session().currentUsername;
    final doc = await FirebaseFirestore.instance
        .collection('user_preferences')
        .doc(username)
        .get();
    if (doc.exists && doc.data()?['weeklyGoalMinutes'] != null) {
      final val = (doc.data()!['weeklyGoalMinutes'] as num).toInt();
      if (val > 0) {
        setState(() => _userSetGoal = val);
      }
    }
  }

  Future<void> _saveUserGoal(int minutes) async {
    final username = Session().currentUsername;
    await FirebaseFirestore.instance
        .collection('user_preferences')
        .doc(username)
        .set({'weeklyGoalMinutes': minutes}, SetOptions(merge: true));
  }

  void _showGoalPicker(BuildContext context, int currentGoal) {
    final controller =
    TextEditingController(text: currentGoal.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Set weekly goal',
          style: GoogleFonts.barlowCondensed(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHO recommends 150 min/week minimum.',
              style: GoogleFonts.barlowCondensed(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.barlowCondensed(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                suffixText: 'min',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap Auto to let the app calculate based on your history.',
              style: GoogleFonts.barlowCondensed(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() => _userSetGoal = null);
              await _saveUserGoal(0); // 0 = auto
              Navigator.pop(ctx);
            },
            child: Text(
              'Auto',
              style: GoogleFonts.barlowCondensed(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 30) {
                setState(() => _userSetGoal = val);
                await _saveUserGoal(val);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: GoogleFonts.barlowCondensed(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
            // ── ALL-TIME TOTALS ──
            int totalCalories = 0;
            int totalDuration = 0;
            int totalWorkouts = 0;

            // ── TODAY ──
            int todayCalories = 0;
            int todayDuration = 0;

            // ── THIS WEEK ──
            int weeklyCalories = 0;
            int weeklyDuration = 0;

            // ── THIS MONTH ──
            int monthlyCalories = 0;
            int monthlyDuration = 0;

            // ── STREAK ──
            int streak = 0;

            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final startOfWeek =
            startOfDay.subtract(Duration(days: now.weekday - 1));
            final startOfMonth = DateTime(now.year, now.month, 1);

            List<DateTime> workoutDates = [];

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;
              totalWorkouts = docs.length;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;

                final duration =
                (data['duration'] as num? ?? 0).toInt();
                final calories =
                (data['calories'] as num? ?? 0).toInt();

                totalCalories += calories;
                totalDuration += duration;

                if (data['completedAt'] != null) {
                  final completedAt =
                  (data['completedAt'] as Timestamp).toDate();

                  workoutDates.add(DateTime(
                    completedAt.year,
                    completedAt.month,
                    completedAt.day,
                  ));

                  // TODAY
                  if (completedAt.isAfter(startOfDay)) {
                    todayCalories += calories;
                    todayDuration += duration;
                  }

                  // WEEK
                  if (completedAt.isAfter(startOfWeek)) {
                    weeklyCalories += calories;
                    weeklyDuration += duration;
                  }

                  // MONTH
                  if (completedAt.isAfter(startOfMonth)) {
                    monthlyCalories += calories;
                    monthlyDuration += duration;
                  }
                }
              }

              // ── STREAK LOGIC ──
              workoutDates = workoutDates.toSet().toList();
              workoutDates.sort((a, b) => b.compareTo(a));

              DateTime checkDate =
              DateTime(now.year, now.month, now.day);

              for (DateTime date in workoutDates) {
                if (date == checkDate ||
                    date ==
                        checkDate
                            .subtract(const Duration(days: 1))) {
                  streak++;
                  checkDate =
                      date.subtract(const Duration(days: 1));
                } else {
                  break;
                }
              }
            }

            // ── REAL GOAL — history-based with WHO fallback ──
            final weeklyGoal = calculateWeeklyGoal(
              docs: snapshot.hasData ? snapshot.data!.docs : [],
              userSetGoal: _userSetGoal,
            );

            double weeklyProgress =
                (weeklyDuration / 60) / weeklyGoal;
            if (weeklyProgress > 1.0) weeklyProgress = 1.0;

            // ── FITNESS LEVEL ──
            String fitnessLevel = 'Beginner';
            if (totalWorkouts >= 30) {
              fitnessLevel = 'Advanced';
            } else if (totalWorkouts >= 10) {
              fitnessLevel = 'Intermediate';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── TOP BAR ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VIGOR',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 36,
                          letterSpacing: 4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const WorkoutHistory(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.history_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── GREETING ──
                  Text(
                    'Good ${_greeting()},',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    username ?? 'Athlete',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── STREAK CARD ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔥 $streak Day Streak',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greenDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$fitnessLevel Athlete',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // ── GOAL BADGE (tappable) ──
                        GestureDetector(
                          onTap: () =>
                              _showGoalPicker(context, weeklyGoal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                              AppColors.green.withOpacity(0.2),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$weeklyGoal min',
                                  style:
                                  GoogleFonts.barlowCondensed(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.greenDark,
                                  ),
                                ),
                                Text(
                                  _userSetGoal != null
                                      ? 'your goal  ✎'
                                      : 'auto goal  ✎',
                                  style:
                                  GoogleFonts.barlowCondensed(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── WEEKLY ACTIVITY PANE ──
                  _ActivityPane(
                    totalCalories: weeklyCalories,
                    totalWorkouts: totalWorkouts,
                    totalDuration: weeklyDuration,
                    weeklyProgress: weeklyProgress,
                    weeklyGoal: weeklyGoal,
                  ),

                  const SizedBox(height: 16),

                  // ── TODAY STATS ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.card),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        _todayStat(
                          '🔥',
                          '$todayCalories',
                          'Today kcal',
                        ),
                        _todayStat(
                          '⏱',
                          '${(todayDuration / 60).floor()}',
                          'Today min',
                        ),
                        _todayStat(
                          '🎯',
                          '$weeklyGoal',
                          'Weekly goal',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── TIP OF THE DAY ──
                  _TipCard(tip: _todayTip),

                  const SizedBox(height: 20),

                  // ── EXERCISE OF THE DAY ──
                  _ExerciseOfDayCard(exercise: _todayExercise),

                  const SizedBox(height: 28),

                  // ── AVAILABLE WORKOUTS ──
                  Text(
                    'AVAILABLE WORKOUTS',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 12),

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
                      final Map<String, Map<String, dynamic>>
                      uniqueMap = {};
                      for (var w in workouts) {
                        uniqueMap[w['title']] = w;
                      }
                      final uniqueWorkouts =
                      uniqueMap.values.toList();

                      if (uniqueWorkouts.isEmpty) {
                        return Center(
                          child: Text(
                            'No workouts available',
                            style: GoogleFonts.barlowCondensed(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount: uniqueWorkouts.length,
                        itemBuilder: (context, index) {
                          final workout = uniqueWorkouts[index];
                          final model =
                          WorkoutModel.fromMap(workout);
                          return _WorkoutCard(
                            workout: model,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StartWorkoutPage(
                                    workout: model),
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

  Widget _todayStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.barlowCondensed(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

// ─────────────────────────────────────────
// ACTIVITY PANE — weekly stats
// ─────────────────────────────────────────
class _ActivityPane extends StatelessWidget {
  final int totalCalories;
  final int totalWorkouts;
  final int totalDuration;
  final double weeklyProgress;
  final int weeklyGoal;

  const _ActivityPane({
    required this.totalCalories,
    required this.totalWorkouts,
    required this.totalDuration,
    required this.weeklyProgress,
    required this.weeklyGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _stat(
                  '${(totalDuration / 60).floor()}',
                  'min trained',
                  Icons.timer_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _stat(
                  '$totalCalories',
                  'kcal burned',
                  Icons.local_fire_department_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _stat(
                  '$totalWorkouts',
                  'workouts',
                  Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly goal',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${(totalDuration / 60).floor()} / $weeklyGoal min',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: weeklyProgress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.green),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.bebasNeue(
            fontSize: 26,
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
    );
  }

  Widget _divider() {
    return Container(
      height: 40,
      width: 0.5,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// ─────────────────────────────────────────
// TIP OF THE DAY
// ─────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final Map<String, String> tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.greenLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(tip['icon']!, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIP OF THE DAY',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.greenDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip['tip']!,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// EXERCISE OF THE DAY
// ─────────────────────────────────────────
class _ExerciseOfDayCard extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const _ExerciseOfDayCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.card),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                exercise['icon'],
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXERCISE OF THE DAY',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise['name'],
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  exercise['muscle'],
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              exercise['sets'],
              style: GoogleFonts.barlowCondensed(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.greenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// WORKOUT CARD
// ─────────────────────────────────────────
class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final VoidCallback onTap;

  const _WorkoutCard({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.card),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('🏋️', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${workout.category}  ·  ${(workout.duration / 60).floor()} min  ·  ${workout.calories} kcal',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'START',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}