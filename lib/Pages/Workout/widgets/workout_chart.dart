import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/session.dart';

class WorkoutChart extends StatelessWidget {
  const WorkoutChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workout_history')
          .where('username', isEqualTo: Session.getUser())
          .snapshots(),
      builder: (context, snapshot) {
        List<double> weeklyData = List.filled(7, 0);

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            if (data['timestamp'] != null) {
              Timestamp timestamp = data['timestamp'];
              DateTime date = timestamp.toDate();

              int weekday = date.weekday - 1;

              int calories = (data['calories'] ?? 0) as int;

              weeklyData[weekday] += calories.toDouble();
            }
          }
        }

        double maxValue = 1;

        for (var value in weeklyData) {
          if (value > maxValue) {
            maxValue = value;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Calories Burned',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    double height =
                        (weeklyData[index] / maxValue) * 120;

                    return Column(
                      mainAxisAlignment:
                      MainAxisAlignment.end,
                      children: [
                        Text(
                          weeklyData[index]
                              .toInt()
                              .toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          width: 26,
                          height: height < 8 ? 8 : height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade300,
                                Colors.deepPurple.shade700,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}