import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../main.dart';
import '../../session.dart';

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

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final int score = ((calories + reps) * 1.3).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── SUCCESS BADGE ──
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.greenDark,
                  size: 48,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'WORKOUT COMPLETE',
                style: GoogleFonts.bebasNeue(
                  fontSize: 36,
                  letterSpacing: 3,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // ── MAIN CALORIES HERO ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      '$calories',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 72,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'CALORIES BURNED',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── STATS GRID ──
              Row(
                children: [
                  _statCard(
                    Icons.timer_rounded,
                    _formatTime(duration),
                    'Duration',
                    AppColors.blue,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    Icons.repeat_rounded,
                    '$reps',
                    'Total Reps',
                    AppColors.green,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _statCard(
                    Icons.emoji_events_rounded,
                    '$score',
                    'Score',
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    Icons.check_circle_rounded,
                    'Done',
                    'Status',
                    AppColors.greenDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── MOTIVATION CARD ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.card),
                ),
                child: Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      'Keep Going!',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 26,
                        color: AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Every workout builds your stronger version. Show up again tomorrow.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── BACK BUTTON ──
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NavigationPage(
                        username: Session().currentUsername ?? 'User',
                      ),
                    ),
                        (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'BACK TO DASHBOARD',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 20,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.card),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.bebasNeue(
                fontSize: 26,
                color: AppColors.textPrimary,
                letterSpacing: 1,
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
        ),
      ),
    );
  }
}
