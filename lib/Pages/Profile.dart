import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final ref = FirebaseFirestore.instance.collection('user_profiles');

  // 🔔 ADD NOTIFICATION
  Future<void> addNotification(String title, String msg) async {
    await ref.doc(widget.username)
        .collection('notifications')
        .add({
      'title': title,
      'message': msg,
      'time': Timestamp.now(),
    });
  }

  String today() {
    const days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];
    return days[DateTime.now().weekday - 1];
  }

  // 🏋️ UPDATE STEPS + GRAPH
  Future<void> updateSteps(String workout) async {

    int steps = 1000;
    if (workout == "Running") steps = 4000;
    if (workout == "Walking") steps = 2000;
    if (workout == "Cycling") steps = 3000;

    final doc = await ref.doc(widget.username).get();

    final data = (doc.data() ?? {}) as Map<String, dynamic>;

    int current = data['stepsToday'] ?? 0;

    Map<String, dynamic> history =
    Map<String, dynamic>.from(data['activityHistory'] ?? {});

    history[today()] = (history[today()] ?? 0) + steps;

    await ref.doc(widget.username).update({
      'stepsToday': current + steps,
      'lastWorkout': workout,
      'activityHistory': history
    });

    addNotification("Workout 🏋️", "$workout added $steps steps");
  }

  // 🍽️ ADD MEAL
  Future<void> addMeal(String meal) async {
    await ref.doc(widget.username).update({
      'lastMeal': meal
    });

    addNotification("Meal 🍽️", "$meal added");
  }

  // 🧠 INIT USER
  Future<void> initUser(DocumentSnapshot doc) async {
    if (!doc.exists) {
      await ref.doc(widget.username).set({
        'name': widget.username,
        'stepsToday': 0,
        'stepGoal': 6000,
        'water': 0,
        'calories': 0,
        'lastMeal': "",
        'lastWorkout': "",
        'activityHistory': {
          "Mon":0,"Tue":0,"Wed":0,
          "Thu":0,"Fri":0,"Sat":0,"Sun":0
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: ref.doc(widget.username).snapshots(),
        builder: (context, snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data!;
          initUser(doc);

          if (!doc.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = (doc.data() ?? {}) as Map<String, dynamic>;

          final history = Map<String, dynamic>.from(
              data['activityHistory'] ?? {});

          final days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [

              // HEADER
              Card(
                color: Colors.deepPurple,
                child: ListTile(
                  title: Text(data['name'] ?? "User",
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    "Steps: ${data['stepsToday'] ?? 0}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),

              // STATS
              Row(children: [
                stat("Steps", data['stepsToday'] ?? 0),
                stat("Goal", data['stepGoal'] ?? 6000),
              ]),
              Row(children: [
                stat("Water", data['water'] ?? 0),
                stat("Calories", data['calories'] ?? 0),
              ]),

              // 🍽️ LAST MEAL
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: const Text("Latest Meal"),
                  subtitle: Text(
                      (data['lastMeal'] ?? "") == ""
                          ? "No meal added"
                          : data['lastMeal']),
                ),
              ),

              // 🏋️ LAST WORKOUT
              Card(
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: const Text("Latest Workout"),
                  subtitle: Text(
                      (data['lastWorkout'] ?? "") == ""
                          ? "No workout"
                          : data['lastWorkout']),
                ),
              ),

              // GRAPH
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: days.map((d) {
                      int v = history[d] ?? 0;
                      return Column(
                        children: [
                          Text("$v"),
                          Container(
                            height: (v / 100).clamp(10, 100),
                            width: 8,
                            color: Colors.deepPurple,
                          ),
                          Text(d),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              // DEMO BUTTONS
              ElevatedButton(
                onPressed: () => updateSteps("Running"),
                child: const Text("Add Running"),
              ),

              ElevatedButton(
                onPressed: () => addMeal("Healthy Meal"),
                child: const Text("Add Meal"),
              ),

              // REMINDER
              ElevatedButton(
                onPressed: () {
                  TextEditingController c = TextEditingController();

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Reminder"),
                      content: TextField(controller: c),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await ref.doc(widget.username)
                                .collection('reminders')
                                .add({
                              'text': c.text,
                              'time': Timestamp.now()
                            });

                            addNotification("Reminder ⏰", c.text);
                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        )
                      ],
                    ),
                  );
                },
                child: const Text("Add Reminder"),
              ),

              // NAV
              ListTile(
                title: const Text("Notifications"),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              NotificationPage(username: widget.username)));
                },
              ),

              ListTile(
                title: const Text("Edit Profile"),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditProfilePage(username: widget.username)));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget stat(String t, dynamic v) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text("$v"),
              Text(t),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔔 NOTIFICATIONS
class NotificationPage extends StatelessWidget {
  final String username;
  const NotificationPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(username)
            .collection('notifications')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView(
            children: docs.map((d) {
              return ListTile(
                title: Text(d['title'] ?? ""),
                subtitle: Text(d['message'] ?? ""),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ✏️ EDIT PROFILE (12 FIELDS)
class EditProfilePage extends StatefulWidget {
  final String username;
  const EditProfilePage({super.key, required this.username});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  final ref = FirebaseFirestore.instance.collection('user_profiles');

  final fields = [
    "name","age","gender","weight","height","goal",
    "city","phone","diet","sleep","medical","notes"
  ];

  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();

    for (var f in fields) {
      controllers[f] = TextEditingController();
    }

    load();
  }

  void load() async {
    final doc = await ref.doc(widget.username).get();
    if (doc.exists) {
      final data = doc.data()!;
      for (var f in fields) {
        controllers[f]!.text = data[f]?.toString() ?? "";
      }
      setState(() {});
    }
  }

  void save() async {
    Map<String, dynamic> data = {};
    controllers.forEach((k, v) => data[k] = v.text);

    await ref.doc(widget.username).update(data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: controllers[f],
              decoration: InputDecoration(labelText: f),
            ),
          )),
          ElevatedButton(onPressed: save, child: const Text("Save"))
        ],
      ),
    );
  }
}
