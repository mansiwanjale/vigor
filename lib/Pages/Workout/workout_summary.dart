import 'package:flutter/material.dart';
import 'package:vigor/main.dart';
import 'package:vigor/session.dart';
import 'workout_home.dart';

class WorkoutSummary extends StatelessWidget {
  final String title;
  final int duration;
  final int calories;
  final int reps;

  const WorkoutSummary({
    Key? key,
    required this.title,
    required this.duration,
    required this.calories,
    required this.reps,
  }) : super(key: key);

  String formatTime(int sec) {
    int min = sec ~/ 60;
    int rem = sec % 60;
    return '${min.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    int score = ((calories + reps) * 1.3).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [

              const SizedBox(height: 10),

              // ─── SUCCESS ICON ───
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.15),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 70,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Workout Complete 🎉",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // ─── MAIN CALORIES CARD ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Text(
                      "$calories",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Calories Burned",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ─── STATS ROW 1 ───
              Row(
                children: [
                  _card("Duration", formatTime(duration), Icons.timer),
                  const SizedBox(width: 12),
                  _card("Reps", "$reps", Icons.repeat),
                ],
              ),

              const SizedBox(height: 12),

              // ─── STATS ROW 2 ───
              Row(
                children: [
                  _card("Score", "$score", Icons.emoji_events),
                  const SizedBox(width: 12),
                  _card("Status", "Completed", Icons.check_circle),
                ],
              ),

              const SizedBox(height: 25),

              // ─── MOTIVATION CARD ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text(
                      "Keep Going 🔥",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Every workout builds your stronger version.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ─── BUTTON ───
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NavigationPage(
                        username:
                        Session().currentUsername ?? "User",
                      ),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Back to Dashboard",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurpleAccent),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}