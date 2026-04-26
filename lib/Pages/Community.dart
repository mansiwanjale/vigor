import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SocialService.dart';
import 'ChatPage.dart'; // we'll create this next
import '../session.dart';

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

// ─────────────────────────────────────────────────────────────
class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});
  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final SocialService _social = SocialService();
  final TextEditingController _searchController = TextEditingController();

  void _showSearchSheet() {
    _searchController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Find a Buddy",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Enter username or email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text("Send Friend Request"),
                onPressed: () async {
                  final query = _searchController.text.trim();
                  if (query.isEmpty) return;

                  try {
                    final user = await _social.findUser(query);
                    if (user == null) throw "User not found";

                    await _social.sendFriendRequest(user['id']);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Request sent to ${user['id']}!")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showIncomingRequests(List<QueryDocumentSnapshot> requests) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Friend Requests",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (_, i) {
                final req = requests[i];
                final from = req['from'] as String;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(from),
                  subtitle: const Text("wants to be your buddy"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await _social.acceptRequest(req.id, from);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await _social.declineRequest(req.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _social.incomingRequests,
      builder: (context, reqSnapshot) {
        final pendingRequests = reqSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: _social.myFriends,
          builder: (context, friendsSnapshot) {
            final friendships = friendsSnapshot.data?.docs ?? [];

            return Stack(
              children: [
                // ── Friends List ──
                friendships.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("No buddies yet — add some!",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: friendships.length,
                  itemBuilder: (_, i) {
                    final data =
                    friendships[i].data() as Map<String, dynamic>;
                    final participants =
                    List<String>.from(data['participants']);
                    final friendName = participants.firstWhere(
                            (p) => p != Session().currentUsername);

                    return ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.person)),
                      title: Text(friendName),
                      subtitle: const Text("Tap to chat"),
                      trailing: const Icon(Icons.chat_bubble_outline),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatPage(friendUsername: friendName),
                          ),
                        );
                      },
                    );
                  },
                ),

                // ── Incoming Requests Bell ──
                if (pendingRequests.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _showIncomingRequests(pendingRequests),
                      child: Stack(
                        children: [
                          const Icon(Icons.notifications,
                              size: 36, color: Colors.blue),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: Colors.red,
                              child: Text(
                                '${pendingRequests.length}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Add Friend FAB ──
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
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
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
          onTap: () {},
        );
      },
    );
  }
}