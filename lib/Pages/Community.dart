import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'SocialService.dart';
import 'ChatPage.dart'; // we'll create this next
import '../session.dart';
import 'TribeChatPage.dart';

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

// ───────────────TRIBES──────────────────────────────────────────────



class TribesTab extends StatefulWidget {
  const TribesTab({super.key});
  @override
  State<TribesTab> createState() => _TribesTabState();
}

class _TribesTabState extends State<TribesTab> {
  final SocialService _social = SocialService();

  // Category options
  static const categories = ['Yoga & Zen', 'Weight Loss', 'Muscle Gain', 'Clean Eating', 'Endurance', 'General'];
  static const categoryIcons = {
    'Yoga & Zen': '🧘',
    'Weight Loss': '🔥',
    'Muscle Gain': '💪',
    'Clean Eating': '🥗',
    'Endurance': '🏃',
    'General': '⚡',
  };

  void _showCreateTribeSheet() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Create a Tribe",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Build your fitness community",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),

                TextField(
                  controller: nameCtrl,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: "Tribe Name *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.groups),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                        '${categoryIcons[c]} $c'),
                  ))
                      .toList(),
                  onChanged: (val) =>
                      setSheetState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Create Tribe"),
                    onPressed: () async {
                      try {
                        await _social.createTribe(
                          name: nameCtrl.text,
                          description: descCtrl.text,
                          category: selectedCategory,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Tribe created! 🎉")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJoinByCodeSheet() {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Join a Tribe",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Enter the invite code shared with you",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Invite Code (e.g. YOG-X4K)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Join Tribe"),
                onPressed: () async {
                  try {
                    await _social.joinTribeByCode(codeCtrl.text);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Joined tribe! 💪")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTribeOptions(DocumentSnapshot tribe) {
    final data = tribe.data() as Map<String, dynamic>;
    final isOwner = data['owner'] == Session().currentUsername;
    final inviteCode = data['inviteCode'] ?? '';
    final members = List<String>.from(data['members'] ?? []);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_TribesTabState.categoryIcons[data['category']] ?? '⚡'} ${data['name']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text("Owner", style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                  ),
                ]
              ],
            ),
            const SizedBox(height: 4),
            Text(data['description'] ?? '',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('${members.length} member${members.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 24),

            // Invite code row
            Row(
              children: [
                const Icon(Icons.vpn_key, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text("Invite Code: ",
                    style: TextStyle(color: Colors.grey[600])),
                Text(inviteCode,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Code copied!")),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Invite a friend (owner only)
            if (isOwner)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_add, color: Colors.blue),
                title: const Text("Invite a Friend"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showInviteFriendSheet(tribe.id);
                },
              ),

            // Members list (owner only)
            if (isOwner)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people, color: Colors.blue),
                title: const Text("Manage Members"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMembersSheet(tribe.id, members, isOwner: true);
                },
              ),

            // Leave tribe (non-owner)
            if (!isOwner)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text("Leave Tribe"),
                onTap: () async {
                  try {
                    await _social.leaveTribe(tribe.id);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),

            // Delete tribe (owner only)
            if (isOwner)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Delete Tribe",
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete Tribe?"),
                      content: const Text(
                          "This will permanently delete the tribe and all its messages."),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete",
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _social.deleteTribe(tribe.id);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showInviteFriendSheet(String tribeId) async {
    final friends = await _social.getMyFriendUsernames();

    if (!mounted) return;

    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have no friends to invite yet!")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Invite a Friend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (_, i) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(friends[i]),
                trailing: ElevatedButton(
                  child: const Text("Invite"),
                  onPressed: () async {
                    try {
                      await _social.inviteFriendToTribe(tribeId, friends[i]);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${friends[i]} added to tribe!")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersSheet(String tribeId, List<String> members,
      {required bool isOwner}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Members",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (_, i) {
                final m = members[i];
                final isMe = m == Session().currentUsername;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    isMe ? Colors.blue[100] : Colors.grey[200],
                    child: Text(m[0].toUpperCase()),
                  ),
                  title: Text(m + (isMe ? ' (you)' : '')),
                  trailing: isOwner && !isMe
                      ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: () async {
                      try {
                        await _social.removeMember(tribeId, m);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$m removed")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    },
                  )
                      : null,
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
      stream: _social.myTribes,
      builder: (context, snap) {
        final tribes = snap.data?.docs ?? [];

        return Stack(
          children: [
            tribes.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No tribes yet — create or join one!",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: tribes.length,
              padding: const EdgeInsets.only(bottom: 80),
              itemBuilder: (_, i) {
                final data =
                tribes[i].data() as Map<String, dynamic>;
                final members =
                List<String>.from(data['members'] ?? []);
                final isOwner =
                    data['owner'] == Session().currentUsername;

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: Text(
                        categoryIcons[data['category']] ?? '⚡',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(data['name'] ?? ''),
                        if (isOwner) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                        ]
                      ],
                    ),
                    subtitle: Text(
                        '${members.length} member${members.length == 1 ? '' : 's'} · ${data['category']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TribeChatPage(
                            tribeId: tribes[i].id,
                            tribeName: data['name'] ?? 'Tribe',
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showTribeOptions(tribes[i]),
                  ),
                );
              },
            ),

            // ── FABs ──
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'join',
                    onPressed: _showJoinByCodeSheet,
                    icon: const Icon(Icons.login),
                    label: const Text("Join"),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.extended(
                    heroTag: 'create',
                    onPressed: _showCreateTribeSheet,
                    icon: const Icon(Icons.add),
                    label: const Text("Create Tribe"),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}