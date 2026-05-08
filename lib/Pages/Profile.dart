import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vigor/Auth/login_page.dart' as auth_login;
import 'package:vigor/Pages/Notifications.dart';
import '../main.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  int _parse(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final userProfileRef =
    FirebaseFirestore.instance.collection('user_profiles').doc(username);
    final usersRef =
    FirebaseFirestore.instance.collection('users').doc(username);

    final profileFields = [
      "name", "age", "gender", "weight",
      "height", "goal", "city", "phone"
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: usersRef.snapshots(), // name/city/goal live here
        builder: (context, authSnap) {
          final authData = authSnap.hasData
              ? (authSnap.data!.data() as Map<String, dynamic>? ?? {})
              : <String, dynamic>{};

          return StreamBuilder<DocumentSnapshot>(
            stream: userProfileRef.snapshots(), // water/steps live here
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.green));
              }

              final profileData =
                  profileSnap.data!.data() as Map<String, dynamic>? ?? {};

              // Merge — authData (users) wins for display fields
              final merged = {...profileData, ...authData};

              final String displayName =
              merged['name']?.toString().isNotEmpty == true
                  ? merged['name']
                  : username;
              final String displayCity =
              merged['city']?.toString().isNotEmpty == true
                  ? merged['city']
                  : 'No city set';
              final String displayGoal =
              merged['goal']?.toString().isNotEmpty == true
                  ? merged['goal']
                  : 'No goal set';

              int water    = _parse(profileData['water']);
              int stepGoal = _parse(profileData['stepGoal']);
              int safeGoal = stepGoal == 0 ? 6000 : stepGoal;

              int filled = profileFields.where((f) =>
              merged[f] != null &&
                  merged[f].toString().isNotEmpty).length;
              int percent =
              ((filled / profileFields.length) * 100).toInt();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('workout_history')
                    .where('username', isEqualTo: username)
                    .snapshots(),
                builder: (context, workoutSnap) {
                  int totalSteps  = 0;
                  int totalBurned = 0;

                  if (workoutSnap.hasData) {
                    for (var d in workoutSnap.data!.docs) {
                      final m = d.data() as Map<String, dynamic>;
                      totalSteps  += _parse(m['steps'] ?? m['duration']);
                      totalBurned += _parse(m['calories'] ?? m['burned']);
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
                          totalGained += _parse(m['calories'] ?? m['gained']);
                        }
                      }

                      int healthScore = (((totalSteps / safeGoal) * 50) +
                          ((water / 2000) * 50))
                          .clamp(0, 100)
                          .toInt();

                      return CustomScrollView(
                        slivers: [
                      // ── Header ────────────────────────
                      SliverToBoxAdapter(
                      child: Container(
                      color: AppColors.blue,
                        padding:
                        const EdgeInsets.fromLTRB(24, 56, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                // Avatar
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.greenLight,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: AppColors.greenDark,
                                      size: 32),
                                ),
                                // Action buttons
                                Row(
                                  children: [
                                    // Activity bell
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ActivityPage(
                                                username: username)),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                            Icons.bar_chart_rounded,
                                            color: AppColors.white,
                                            size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Logout
                                    GestureDetector(
                                      onTap: () async {
                                        await FirebaseAuth.instance
                                            .signOut();
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                              const auth_login
                                                  .LoginPage()),
                                              (route) => false,
                                        );
                                      },
                                      child: Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.logout_rounded,
                                                color: AppColors.white,
                                                size: 16),
                                            SizedBox(width: 6),
                                            Text('Logout',
                                                style: TextStyle(
                                                    color: AppColors.white,
                                                    fontSize: 13,
                                                    fontWeight:
                                                    FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(displayName,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.white54, size: 14),
                                const SizedBox(width: 4),
                                Text(displayCity,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13)),
                                const SizedBox(width: 12),
                                const Icon(Icons.flag_rounded,
                                    color: Colors.white54, size: 14),
                                const SizedBox(width: 4),
                                Text(displayGoal,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),

                      // ── Body ──────────────────────────
                      SliverToBoxAdapter(
                      child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Stats
                      Row(children: [
                      _statTile('Steps', '$totalSteps',
                      Icons.directions_walk_rounded,
                      const Color(0xFF5C7C8A)),
                      const SizedBox(width: 12),
                      _statTile('Burned', '${totalBurned}kcal',
                      Icons.local_fire_department_rounded,
                      const Color(0xFFE07A5F)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                      _statTile('Gained', '${totalGained}kcal',
                      Icons.restaurant_rounded,
                      const Color(0xFF6FBF9F)),
                      const SizedBox(width: 12),
                      _statTile('Health', '$healthScore/100',
                      Icons.favorite_rounded,
                      const Color(0xFFBF6F6F)),
                      ]),

                      const SizedBox(height: 24),

                      // ── Hydration ─────────────
                      const Text('Hydration',
                      style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3)),
                      const SizedBox(height: 12),
                      Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                      Row(
                      children: [
                      Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                      color:
                      const Color(0xFFDCEEF5),
                      borderRadius:
                      BorderRadius.circular(12),
                      ),
                      child: const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF5C7C8A),
                      size: 20),
                      ),
                      const SizedBox(width: 14),
                      Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                      Text('$water ml',
                      style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w700,
                      color: AppColors
                          .textPrimary)),
                      const Text(
                      'of 2000 ml daily goal',
                      style: TextStyle(
                      color: AppColors
                          .textSecondary,
                      fontSize: 12)),
                      ],
                      ),
                      const Spacer(),
                      Text(
                      '${((water / 2000) * 100).clamp(0, 100).toInt()}%',
                      style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                      ),
                      ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                      borderRadius:
                      BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                      value:
                      (water / 2000).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor:
                      AppColors.inputField,

                      ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                      children: [
                      Expanded(
                      child: _WaterButton(
                      imagePath:
                      'assets/images/GLASS.png',
                      label: '+200 ml',
                      onTap: () async {
                      await userProfileRef.set(
                      {'water': FieldValue.increment(200)},
                      SetOptions(merge: true),
                      );
                      await showWaterNotification(200);
                      },
                      ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                      child: _WaterButton(
                      imagePath:
                      'assets/images/JUG.png',
                      label: '+500 ml',
                      onTap: () async {
                      await userProfileRef.set(
                      {'water': FieldValue.increment(500)},
                      SetOptions(merge: true),
                      );
                      await showWaterNotification(500);
                      },
                      isPrimary: true,
                      ),
                      ),
                      ],
                      ),
                      ],
                      ),
                      ),

                      const SizedBox(height: 24),

                      // ── Profile completion ─────
                      const Text('Profile',
                      style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3)),
                      const SizedBox(height: 12),
                      Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                      children: [
                      Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                      const Text('Completion',
                      style: TextStyle(
                      color:
                      AppColors.textSecondary,
                      fontSize: 13)),
                      Text('$percent%',
                      style: const TextStyle(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
                      ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                      borderRadius:
                      BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      backgroundColor:
                      AppColors.inputField,

                      ),
                      ),
                      ],
                      ),
                      ),

                      const SizedBox(height: 16),

                      _actionTile(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                      username: username)),
                      ),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (_) => NotificationPage(
                      username: username)),
                      ),
                      ),
                      const SizedBox(height: 32),
                      ],
                      ),
                      ),
                      ),
                      ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

extension on Type {
  void operator >(Color other) {}
}

// ── Water Button ────────────────────────────────────────────
class _WaterButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _WaterButton({
    required this.imagePath,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.greenDark : AppColors.inputField,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, height: 32),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPrimary
                        ? AppColors.white
                        : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Edit Profile ────────────────────────────────────────────
class EditProfilePage extends StatefulWidget {
  final String username;

  const EditProfilePage({super.key, required this.username});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileRef = FirebaseFirestore.instance.collection('user_profiles');
  final _usersRef   = FirebaseFirestore.instance.collection('users');

  final fields = ["name","age","gender","weight","height","goal","city","phone"];
  final fieldLabels = {
    "name"  : "Full Name",
    "age"   : "Age",
    "gender": "Gender",
    "weight": "Weight (kg)",
    "height": "Height (cm)",
    "goal"  : "Fitness Goal",
    "city"  : "City",
    "phone" : "Phone Number",
  };

  // ✅ ADDED LABELS (no logic change)
  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    for (var f in fields) controllers[f] = TextEditingController();
    _loadData();
  }

  void _loadData() async {
    final profileDoc = await _profileRef.doc(widget.username).get();
    final usersDoc   = await _usersRef.doc(widget.username).get();
    final merged = {
      if (usersDoc.exists)   ...usersDoc.data()!,
      if (profileDoc.exists) ...profileDoc.data()!,
    };
    for (var f in fields) {
      controllers[f]!.text = merged[f]?.toString() ?? '';
    }
    setState(() {});
  }

  void _saveData() async {
    final Map<String, dynamic> data = {};
    controllers.forEach((k, v) => data[k] = v.text);
    // Write to both collections so display is always consistent
    await _profileRef.doc(widget.username).set(data, SetOptions(merge: true));
    await _usersRef.doc(widget.username).set(data, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  TextInputType _keyboard(String field) {
    switch (field) {
      case 'age': case 'weight': case 'height': case 'phone':
      return TextInputType.number;
      default:
        return TextInputType.text;
    }
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: controllers[f],
              keyboardType: _keyboard(f),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: fieldLabels[f],
                labelStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 15, horizontal: 16),
              ),
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Save Changes',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
