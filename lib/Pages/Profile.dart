import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vigor/Auth/login_page.dart' as auth_login;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

Future<void> showWaterNotification(int amount) async {
  const AndroidNotificationDetails androidDetails =
  AndroidNotificationDetails(
    'water_channel',
    'Water Reminder',
    channelDescription: 'Water tracking notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails details =
  NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    "Water Intake 💧",
    "You added $amount ml water",
    details,
  );
}

class ProfilePage extends StatelessWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  int parseValue(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final userRef =
    FirebaseFirestore.instance.collection('user_profiles').doc(username);

    final profileFields = [
      "name", "age", "gender", "weight", "height", "goal",
      "city", "phone"
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityPage(username: username),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const auth_login.LoginPage()),
                      (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
          )
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: userRef.snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userSnap.data!.data() as Map<String, dynamic>? ?? {};

          int water = parseValue(userData['water']);
          int goal = parseValue(userData['stepGoal']);
          int safeGoal = goal == 0 ? 6000 : goal;

          int filled = profileFields.where((f) {
            return userData[f] != null &&
                userData[f].toString().isNotEmpty;
          }).length;

          int percent = ((filled / profileFields.length) * 100).toInt();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('workouts')
                .where('userId', isEqualTo: username)
                .snapshots(),
            builder: (context, workoutSnap) {

              int totalSteps = 0;
              int totalBurned = 0;

              if (workoutSnap.hasData) {
                for (var d in workoutSnap.data!.docs) {
                  final m = d.data() as Map<String, dynamic>;
                  totalSteps += parseValue(m['steps']);
                  totalBurned += parseValue(m['calories']);
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('meals')
                    .where('userId', isEqualTo: username)
                    .snapshots(),
                builder: (context, mealSnap) {

                  int totalGained = 0;

                  if (mealSnap.hasData) {
                    for (var d in mealSnap.data!.docs) {
                      final m = d.data() as Map<String, dynamic>;
                      totalGained += parseValue(m['calories']);
                    }
                  }

                  int healthScore = (
                      ((totalSteps / safeGoal) * 50) +
                          ((water / 2000) * 50)
                  ).clamp(0, 100).toInt();

                  return ListView(
                    padding: const EdgeInsets.all(14),
                    children: [

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.teal, Colors.green],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['name'] ?? username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Steps: $totalSteps",
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(children: [
                        statCard("Steps", totalSteps, Colors.blue),
                        statCard("Goal", safeGoal, Colors.green),
                      ]),

                      Row(children: [
                        statCard("Burned", totalBurned, Colors.red),
                        statCard("Gained", totalGained, Colors.orange),
                      ]),

                      const SizedBox(height: 10),

                      cardBox("Health Score", "$healthScore / 100", Colors.teal),

                      Card(
                        child: Column(
                          children: [
                            const Text("Water Intake"),
                            LinearProgressIndicator(
                              value: (water / 2000).clamp(0, 1),
                            ),
                            Text("$water ml / 2000 ml"),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    await userRef.update({'water': water + 200});
                                    await showWaterNotification(200); // ✅ ADD THIS LINE
                                  },
                                  child: const Text("+200 ml"),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await userRef.update({'water': water + 500});
                                    await showWaterNotification(500); // ✅ ADD THIS LINE
                                  },
                                  child: const Text("+500 ml"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      cardBox("Profile Completion", "$percent%", Colors.indigo),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfilePage(username: username),
                            ),
                          );
                        },
                        child: const Text("Edit Profile"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget statCard(String title, dynamic value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text("$value", style: TextStyle(color: color)),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardBox(String title, String value, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color),
        title: Text(title),
        trailing: Text(value),
      ),
    );
  }
}

//
// ================= EDIT PROFILE PAGE =================
//

class EditProfilePage extends StatefulWidget {
  final String username;

  const EditProfilePage({super.key, required this.username});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  final ref = FirebaseFirestore.instance.collection('user_profiles');

  final fields = [
    "name","age","gender","weight",
    "height","goal","city","phone"
  ];

  // ✅ ADDED LABELS (no logic change)
  final fieldLabels = {
    "name": "Full Name",
    "age": "Age",
    "gender": "Gender",
    "weight": "Weight (kg)",
    "height": "Height (cm)",
    "goal": "Fitness Goal",
    "city": "City",
    "phone": "Phone Number",
  };

  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    for (var f in fields) {
      controllers[f] = TextEditingController();
    }
    loadData();
  }

  void loadData() async {
    final doc = await ref.doc(widget.username).get();
    if (doc.exists) {
      final data = doc.data()!;
      for (var f in fields) {
        controllers[f]!.text = data[f]?.toString() ?? "";
      }
      setState(() {});
    }
  }

  void saveData() async {
    Map<String, dynamic> data = {};
    controllers.forEach((k, v) => data[k] = v.text);

    await ref.doc(widget.username).set(data, SetOptions(merge: true));
    Navigator.pop(context);
  }

  // ✅ ADDED keyboard type helper
  TextInputType getKeyboard(String field) {
    if (field == "age" ||
        field == "weight" ||
        field == "height" ||
        field == "phone") {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: controllers[f],
              keyboardType: getKeyboard(f), // ✅ added
              decoration: InputDecoration(
                labelText: fieldLabels[f], // ✅ replaced label
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          )),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: saveData,
              child: const Text("Save"))
        ],
      ),
    );
  }
}

//
// ================= ACTIVITY PAGE =================
//

class ActivityPage extends StatelessWidget {
  final String username;

  const ActivityPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {

    final workouts = FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: username);

    final meals = FirebaseFirestore.instance
        .collection('meals')
        .where('userId', isEqualTo: username);

    return Scaffold(
      appBar: AppBar(title: const Text("Activity")),
      body: FutureBuilder(
        future: Future.wait([
          workouts.get(),
          meals.get(),
        ]),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final workoutDocs = (snapshot.data as List)[0].docs;
          final mealDocs = (snapshot.data as List)[1].docs;

          List activities = [];

          for (var d in workoutDocs) {
            final m = d.data();
            activities.add({
              'title': "Workout",
              'msg': "Burned ${m['calories'] ?? 0} cal",
            });
          }

          for (var d in mealDocs) {
            final m = d.data();
            activities.add({
              'title': "Meal",
              'msg': "Gained ${m['calories'] ?? 0} cal",
            });
          }

          if (activities.isEmpty) {
            return const Center(child: Text("No Activity"));
          }

          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, i) {
              final a = activities[i];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(a['title']),
                  subtitle: Text(a['msg']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
