import 'dart:async';
import 'package:flutter/material.dart';
import 'models/workout_model.dart';
import 'workout_summary.dart';
import 'services/firestore_workout_service.dart';

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
  int totalSeconds = 300;
  int reps = 0;
  int calories = 0;

  bool isDown = false;

  List<String> motivation = [
    "Keep Going 🔥",
    "Push Harder 💪",
    "Almost There 🚀",
    "You Got This ❤️",
    "Stay Strong ⚡",
  ];

  int currentText = 0;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (seconds < totalSeconds) {
          setState(() {
            seconds++;

            if (seconds % 2 == 0) {
              if (!isDown) {
                isDown = true;
              } else {
                isDown = false;
                reps++;
              }
            }

            calculateCalories();

            if (seconds % 5 == 0) {
              currentText =
                  (currentText + 1) % motivation.length;
            }
          });
        } else {
          finishWorkout();
        }
      },
    );
  }

  void calculateCalories() {
    double userWeight = 63;
    double met = 0;

    switch (widget.workout.category.toLowerCase()) {
      case 'cardio':
        met = 8;
        break;
      case 'strength':
        met = 6;
        break;
      case 'abs':
        met = 5;
        break;
      default:
        met = 6;
    }

    calories =
        ((met * userWeight * (seconds / 3600)) * 1.05).floor();
  }

  void finishWorkout() async {
    timer.cancel();

    final completedWorkout = WorkoutModel(
      title: widget.workout.title,
      category: widget.workout.category,
      duration: seconds,
      calories: calories,
      image: widget.workout.image,
    );

    await FirestoreWorkoutService()
        .saveWorkout(completedWorkout);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummary(
          title: widget.workout.title,
          duration: seconds,
          calories: calories,
          reps: reps,
        ),
      ),
    );
  }

  String formatTime(int sec) {
    int min = sec ~/ 60;
    int rem = sec % 60;

    return '${min.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = seconds / totalSeconds;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                // 🔙 Header
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        timer.cancel();
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.workout.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔥 IMAGE FROM FIREBASE
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius:
                    BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(28),
                    child: Image.network(
                      widget.workout.image.isNotEmpty
                          ? widget.workout.image
                          : "https://images.unsplash.com/photo-1571019613914-85f342c6a11e",
                      fit: BoxFit.cover,

                      // loader
                      loadingBuilder:
                          (context, child, progress) {
                        if (progress == null)
                          return child;
                        return const Center(
                            child:
                            CircularProgressIndicator());
                      },

                      // error fallback
                      errorBuilder:
                          (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 50,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ⏱ Timer Circle
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor:
                        Colors.white12,
                        valueColor:
                        const AlwaysStoppedAnimation(
                          Colors.deepPurple,
                        ),
                      ),
                      Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Text(
                            formatTime(
                                totalSeconds - seconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Remaining",
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 💬 Motivation
                Text(
                  motivation[currentText],
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // 📊 Stats
                Row(
                  children: [
                    Expanded(
                      child: statBox(
                        "Calories",
                        "$calories",
                        Icons.local_fire_department,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: statBox(
                        "Reps",
                        "$reps",
                        Icons.repeat,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 🔴 Finish Button
                ElevatedButton(
                  onPressed: finishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.redAccent,
                    minimumSize:
                    const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Finish Workout",
                    style: TextStyle(fontSize: 18),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget statBox(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.deepPurpleAccent,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}