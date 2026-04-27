import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../session.dart';

class WorkoutChart extends StatelessWidget {
  const WorkoutChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('workout_history')
                  .where('username', isEqualTo: Session.getUser())
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data!.docs;
                final data = _processChartData(docs);

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 60,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'M', 'T', 'W', 'T', 'F', 'S', 'S'
                            ];
                            return Text(
                              days[value.toInt() % 7],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: data,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _processChartData(
      List<QueryDocumentSnapshot> docs) {
    final Map<int, double> dailyMinutes = {
      0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0
    };

    final now = DateTime.now();
    final startOfWeek =
    now.subtract(Duration(days: now.weekday - 1));

    for (var doc in docs) {
      final timestamp = doc['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      final date = timestamp.toDate();
      if (date.isAfter(
          startOfWeek.subtract(const Duration(seconds: 1)))) {
        final dayIndex = date.weekday - 1;
        final duration = (doc['duration'] ?? 0) / 60;
        dailyMinutes[dayIndex] =
            (dailyMinutes[dayIndex] ?? 0) + duration;
      }
    }

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dailyMinutes[i]!,
            color: Colors.deepPurple.shade400,
            width: 14,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 60,
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    });
  }
}
