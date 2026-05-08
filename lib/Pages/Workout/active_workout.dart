import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/workout_model.dart';
import 'services/firestore_workout_service.dart';
import 'workout_summary.dart';
import '../../main.dart';

class ActiveWorkout extends StatefulWidget {
  final WorkoutModel workout;

  const ActiveWorkout({super.key, required this.workout});

  @override
  State<ActiveWorkout> createState() => _ActiveWorkoutState();
}

class _ActiveWorkoutState extends State<ActiveWorkout> {
  Timer? _timer;
  int _seconds = 0;
  bool _isPaused = false;
  late int _totalSeconds;

  // Sets & reps tracking
  int _completedSets = 0;
  int _totalReps = 0;
  final int _targetSets = 4;
  final TextEditingController _repsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _totalSeconds =
    widget.workout.duration > 0 ? widget.workout.duration : 600;

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() {
          if (_seconds < _totalSeconds) {
            _seconds++;
          } else {
            _finishWorkout();
          }
        });
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _logSet() {
    final reps = int.tryParse(_repsController.text) ?? 0;

    if (reps > 0) {
      setState(() {
        _completedSets++;
        _totalReps += reps;
        _repsController.clear();
      });
    }
  }

  // ✅ LIVE CALORIES LOGIC
  double get _liveCalories {
    if (_totalSeconds == 0) return 0;

    return (widget.workout.calories * _seconds) / _totalSeconds;
  }

  Future<void> _finishWorkout() async {
    _timer?.cancel();

    await FirestoreWorkoutService().saveWorkout(
      WorkoutModel(
        title: widget.workout.title,
        category: widget.workout.category,
        duration: _seconds,

        // ✅ SAVE ACTUAL BURNED CALORIES
        calories: _liveCalories.round(),

        image: widget.workout.image,
      ),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummary(
          title: widget.workout.title,
          duration: _seconds,

          // ✅ PASS LIVE CALORIES
          calories: _liveCalories.round(),

          reps: _totalReps,
        ),
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      _totalSeconds == 0 ? 0 : _seconds / _totalSeconds;

  @override
  void dispose() {
    _timer?.cancel();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.card),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.workout.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isPaused
                          ? Colors.orange.withOpacity(0.15)
                          : AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isPaused ? 'PAUSED' : 'LIVE',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: _isPaused
                            ? Colors.orange
                            : AppColors.greenDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── TIMER RING ──
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.card),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: _progress,
                                    strokeWidth: 10,
                                    backgroundColor: AppColors.card,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      _isPaused
                                          ? Colors.orange
                                          : AppColors.green,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'TIME',
                                      style: GoogleFonts.barlowCondensed(
                                        fontSize: 12,
                                        letterSpacing: 2,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(_seconds),
                                      style: GoogleFonts.bebasNeue(
                                        fontSize: 48,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      '/ ${_formatTime(_totalSeconds)}',
                                      style: GoogleFonts.barlowCondensed(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── PAUSE / FINISH ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _togglePause,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                    color: AppColors.textPrimary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _finishWorkout,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.green,
                                    borderRadius:
                                    BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'FINISH',
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 20,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── LIVE STATS ──
                    Row(
                      children: [
                        _liveStat(
                          Icons.local_fire_department_rounded,

                          // ✅ LIVE CALORIES
                          '${_liveCalories.toStringAsFixed(1)} kcal',

                          'calories burned',
                          Colors.orange,
                        ),

                        const SizedBox(width: 12),

                        _liveStat(
                          Icons.fitness_center_rounded,
                          widget.workout.category,
                          'category',
                          AppColors.blue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveStat(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.card),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
}