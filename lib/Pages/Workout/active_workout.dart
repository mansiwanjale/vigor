import 'dart:async';
import 'package:flutter/material.dart';
import 'models/workout_model.dart';
import 'workout_summary.dart';

class ActiveWorkout extends StatefulWidget {
  final WorkoutModel workout;

  const ActiveWorkout({
    Key? key,
    required this.workout,
  }) : super(key: key);

  @override
  State<ActiveWorkout> createState() => _ActiveWorkoutState();
}

class _ActiveWorkoutState extends State<ActiveWorkout> {
  late Timer timer;
  int seconds = 0;
  bool isRunning = true;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isRunning) {
        setState(() {
          seconds++;
        });
      }
    });
  }

  void togglePause() {
    setState(() {
      isRunning = !isRunning;
    });
  }

  void finishWorkout() {
    timer.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummary(
          duration: seconds,
          calories: widget.workout.calories,
          title: widget.workout.title,
        ),
      ),
    );
  }

  String formatTime(int totalSeconds) {
    int mins = totalSeconds ~/ 60;
    int secs = totalSeconds % 60;

    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Text(
                widget.workout.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                widget.workout.category,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.deepPurple,
                    width: 8,
                  ),
                ),
                child: Center(
                  child: Text(
                    formatTime(seconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: togglePause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isRunning ? 'Pause' : 'Resume',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    onPressed: finishWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Finish',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}