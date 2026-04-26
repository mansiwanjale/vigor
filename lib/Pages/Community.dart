import 'package:flutter/material.dart';
import 'SocialService.dart';
class Community extends StatelessWidget {
  const Community({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Vigor Social"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Friends"),
              Tab(icon: Icon(Icons.groups), text: "Tribes"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendsTab(),
            TribesTab(),
          ],
        ),
      ),
    );
  }
}

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final SocialService _social = SocialService();
  final TextEditingController _searchController = TextEditingController();

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Find a Buddy", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: "Enter username or email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final user = await _social.findUser(_searchController.text.trim());
                if (user != null) {
                  // If user found, add them
                  await _social.addFriend(user.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Added ${user['username']}!"))
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User not found"))
                  );
                }
              },
              child: const Text("Add Friend"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(child: Text("Your Buddies will appear here")),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showSearchSheet,
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }
}


class TribesTab extends StatelessWidget {
  const TribesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> tribes = [
      {'id': 'yoga', 'name': 'Yoga & Zen', 'icon': '🧘'},
      {'id': 'weightloss', 'name': 'Weight Loss Warriors', 'icon': '🔥'},
      {'id': 'muscle', 'name': 'Hypertrophy Hub', 'icon': '💪'},
      {'id': 'diet', 'name': 'Clean Eating', 'icon': '🥗'},
    ];

    return ListView.builder(
      itemCount: tribes.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Text(tribes[index]['icon']!),
          ),
          title: Text(tribes[index]['name']!),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            print("Tapped on ${tribes[index]['name']}");
          },
        );
      },
    );
  }
}