import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

// ── Notification plugin — single global instance ────────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<void> showWaterNotification(int amount) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'water_channel',
    'Water Reminder',
    channelDescription: 'Water tracking notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Water Intake 💧',
    'You added $amount ml — keep it up!',
    const NotificationDetails(android: androidDetails),
  );
}

// ── Notification Page ───────────────────────────────────────
class NotificationPage extends StatelessWidget {
  final String username;
  const NotificationPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(username)
        .collection('notifications');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.green));
          }
          if (snap.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded,
                      color: AppColors.textSecondary, size: 48),
                  SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snap.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data =
              snap.data!.docs[i].data() as Map<String, dynamic>;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: AppColors.greenDark, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(data['message'] ?? '',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Activity Page ───────────────────────────────────────────
class ActivityPage extends StatelessWidget {
  final String username;
  const ActivityPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([
          FirebaseFirestore.instance
              .collection('workout_history')
              .where('username', isEqualTo: username)
              .get(),
          FirebaseFirestore.instance
              .collection('meals')
              .where('userId', isEqualTo: username)
              .get(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.green));
          }

          final workoutDocs = (snapshot.data as List)[0].docs;
          final mealDocs    = (snapshot.data as List)[1].docs;

          final List<Map<String, dynamic>> activities = [];

          for (var d in workoutDocs) {
            final m = d.data() as Map<String, dynamic>;
            activities.add({
              'type'  : 'workout',
              'title' : m['title'] ?? 'Workout',
              'msg'   : 'Burned ${m['calories'] ?? m['burned'] ?? 0} kcal',
            });
          }

          for (var d in mealDocs) {
            final m = d.data() as Map<String, dynamic>;
            activities.add({
              'type'  : 'meal',
              'title' : m['name'] ?? 'Meal',
              'msg'   : 'Gained ${m['calories'] ?? 0} kcal',
            });
          }

          if (activities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run_rounded,
                      color: AppColors.textSecondary, size: 48),
                  SizedBox(height: 12),
                  Text('No activity yet',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a           = activities[i];
              final bool isWorkout = a['type'] == 'workout';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isWorkout
                            ? AppColors.greenLight
                            : const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isWorkout
                            ? Icons.fitness_center_rounded
                            : Icons.restaurant_rounded,
                        color: isWorkout
                            ? AppColors.greenDark
                            : const Color(0xFFE07A5F),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(a['msg'],
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}