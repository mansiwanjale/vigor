import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Workout/workout_home.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.fitness_center, size: 100, color: Colors.blueGrey),
            SizedBox(height: 20),
            Text(
              "Workout",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Add user details, settings, or logout button here
          ],
        ),
      ),
    );
  }
}


class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Buddies")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search by username...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase(); // Search is easier in lowercase
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Logic: Find users where username starts with searchText
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('username')
                  .startAt([searchText])
                  .endAt([searchText + '\uf8ff'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(data['username'] ?? "No Name"),
                      subtitle: Text("${data['city']} • Age: ${data['age']}"),
                      trailing: ElevatedButton(
                        onPressed: () => sendRequest(docs[index].id),
                        child: const Text("Add"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void sendRequest(String targetUid) {
    // We'll write this logic next!
    print("Sending request to: $targetUid");
  }
}