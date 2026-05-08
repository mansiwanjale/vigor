import 'dart:async';
import 'package:flutter/material.dart';
import 'models/workout_model.dart';
import 'services/firestore_workout_service.dart';
import 'workout_summary.dart';

class ActiveWorkout extends StatefulWidget {
  final WorkoutModel workout;

  const ActiveWorkout({super.key, required this.workout});

  @override
  State<ActiveWorkout> createState() => _ActiveWorkoutState();
}

class _ActiveWorkoutState extends State<ActiveWorkout> {
  Timer? timer;

  int seconds = 0;
  bool isPaused = false;

  late int totalSeconds;

  @override
  void initState() {
    super.initState();

    totalSeconds = widget.workout.duration > 0
        ? widget.workout.duration
        : 600; // fallback 10 min

    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) {
        setState(() {
          if (seconds < totalSeconds) {
            seconds++;
          } else {
            _finishWorkout();
          }
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  /// ✅ FINISH → SAVE → SHOW SUMMARY
  void _finishWorkout() async {
    timer?.cancel();

    // SAVE TO FIRESTORE HISTORY
    await FirestoreWorkoutService().saveWorkout(
      WorkoutModel(
        title: widget.workout.title,
        category: widget.workout.category,
        duration: seconds,
        calories: widget.workout.calories,
        image: widget.workout.image,
      ),
    );

    if (!mounted) return;

    // GO TO SUMMARY SCREEN
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummary(
          title: widget.workout.title,
          duration: seconds,
          calories: widget.workout.calories,
          reps: 0, // Added default value to fix compilation error
        ),
      ),
    );
  }

  String formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  double get progress => totalSeconds == 0 ? 0 : seconds / totalSeconds;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),

      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 10),

            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      widget.workout.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// TIMER CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [

                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          backgroundColor: Colors.white24,
                          valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                        ),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "TIME",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              formatTime(seconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isPaused ? "Paused" : "Running",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// CATEGORY
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.workout.category,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// CONTROLS
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white10,
                      ),
                      child: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: _finishWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Finish"),
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