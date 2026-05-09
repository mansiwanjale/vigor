import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FriendStatPage
// Shows a friend's public profile: avatar, bio, streak, stats, goals, etc.
// Usage: Navigator.push(context, MaterialPageRoute(
//          builder: (_) => FriendStatPage(username: friendUsername)));
// ─────────────────────────────────────────────────────────────────────────────

class FriendStatPage extends StatelessWidget {
  final String username;
  const FriendStatPage({super.key, required this.username});

  // ── Firestore refs ──────────────────────────────────────────────────────────
  DocumentReference get _userRef =>
      FirebaseFirestore.instance.collection('users').doc(username);
  DocumentReference get _profileRef =>
      FirebaseFirestore.instance.collection('user_profiles').doc(username);

  // ── Helpers ────────────────────────────────────────────────────────────────
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Days since the user joined (streak = consecutive days on app).
  /// We store the join date as a Timestamp or ISO string in users/{uid}.joinedAt.
  int _daysSince(dynamic raw) {
    if (raw == null) return 0;
    DateTime? joined;
    if (raw is Timestamp) joined = raw.toDate();
    if (raw is String)    joined = DateTime.tryParse(raw);
    if (joined == null)   return 0;
    return DateTime.now().difference(joined).inDays;
  }

  String _daysSinceLabel(dynamic raw) {
    final d = _daysSince(raw);
    if (d == 0) return 'Joined today';
    if (d == 1) return '1 day';
    return '$d days';
  }

  // ── Color palette (matches Vigor's AppColors roughly) ──────────────────────
  static const _blue       = Color(0xFF3D8BCD);
  static const _green      = Color(0xFF4CAF82);
  static const _orange     = Color(0xFFE07A5F);
  static const _purple     = Color(0xFF9B8EA8);
  static const _teal       = Color(0xFF5C7C8A);
  static const _bg         = Color(0xFFF5F7FA);
  static const _card       = Colors.white;
  static const _textPri    = Color(0xFF1A1A2E);
  static const _textSec    = Color(0xFF8A8FA8);
  static const _headerH    = 220.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userRef.snapshots(),
        builder: (context, userSnap) {
          final userData =
              (userSnap.data?.data() as Map<String, dynamic>?) ?? {};

          return StreamBuilder<DocumentSnapshot>(
            stream: _profileRef.snapshots(),
            builder: (context, profSnap) {
              final profData =
                  (profSnap.data?.data() as Map<String, dynamic>?) ?? {};

              // Merge: user doc wins for identity fields
              final merged = {...profData, ...userData};

              final avatarUrl = merged['avatar']?.toString() ?? '';
              final name      = merged['name']?.toString() ?? username;
              final city      = merged['city']?.toString() ?? '';
              final bio       = merged['bio']?.toString() ?? '';
              final goal      = merged['goal']?.toString() ?? '';
              final level     = merged['fitnessLevel']?.toString() ?? '';
              final activity  = merged['preferredActivity']?.toString() ?? '';

              final steps      = _toInt(profData['steps'] ?? profData['stepCount']);
              final water      = _toInt(profData['water']);
              final waterGoal  = _toInt(profData['waterGoal'] == null ? 2000 : profData['waterGoal']);
              final stepGoal   = _toInt(profData['stepGoal'] == null ? 6000 : profData['stepGoal']);
              final calories   = _toInt(profData['calories'] ?? profData['caloriesBurned']);
              final workouts   = _toInt(profData['workoutsCompleted'] ?? profData['workouts']);
              final friends    = _toInt(profData['friendsCount'] ?? userData['friendsCount']);
              final streak     = _toInt(profData['streak'] ?? userData['streak']);
              final goalsToday = _toInt(profData['goalsCompletedToday']);
              final joined     = merged['joinedAt'] ?? merged['createdAt'];

              return CustomScrollView(
                slivers: [
                  // ── Hero header ──────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: _headerH,
                    pinned: true,
                    backgroundColor: _blue,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Gradient backdrop
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2C6FAC), Color(0xFF3D8BCD)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Decorative circles
                          Positioned(
                            top: -30, right: -40,
                            child: Container(
                              width: 180, height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20, left: -20,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          // Avatar + name
                          Positioned(
                            bottom: 20, left: 20, right: 20,
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 80, height: 80,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _green, width: 2.5),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black12, width: 1),
                                    ),
                                    child: CircleAvatar(
                                      radius: 38,
                                      backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                      backgroundImage: avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl.isEmpty
                                          ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight:
                                            FontWeight.w800),
                                      )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        if (city.isNotEmpty) ...[
                                          const Icon(
                                              Icons.location_on_rounded,
                                              color: Colors.white60,
                                              size: 12),
                                          const SizedBox(width: 3),
                                          Text(city,
                                              style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12)),
                                          const SizedBox(width: 8),
                                        ],
                                        const Icon(Icons.calendar_today_rounded,
                                            color: Colors.white60, size: 12),
                                        const SizedBox(width: 3),
                                        Text(
                                          _daysSinceLabel(joined),
                                          style: const TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12),
                                        ),
                                      ]),
                                      const SizedBox(height: 6),
                                      // Tags row
                                      Wrap(spacing: 6, children: [
                                        if (level.isNotEmpty)
                                          _tag(level, _green),
                                        if (activity.isNotEmpty)
                                          _tag(activity, _orange),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Body ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Bio ────────────────────────────────────────
                          if (bio.isNotEmpty) ...[
                            _sectionLabel('About'),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Text(
                                bio,
                                style: const TextStyle(
                                    color: _textPri,
                                    fontSize: 14,
                                    height: 1.5),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Quick numbers ───────────────────────────────
                          _sectionLabel('Community'),
                          const SizedBox(height: 10),
                          Row(children: [
                            _bigStatCard(
                              icon: Icons.people_alt_rounded,
                              value: '$friends',
                              label: 'Friends',
                              color: _blue,
                            ),
                            const SizedBox(width: 10),
                            _bigStatCard(
                              icon: Icons.local_fire_department_rounded,
                              value: '$streak',
                              label: 'Day Streak',
                              color: _orange,
                            ),
                            const SizedBox(width: 10),
                            _bigStatCard(
                              icon: Icons.fitness_center_rounded,
                              value: '$workouts',
                              label: 'Workouts',
                              color: _green,
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // ── Today's activity ────────────────────────────
                          _sectionLabel("Today's Activity"),
                          const SizedBox(height: 10),

                          // Steps progress
                          _progressCard(
                            icon: Icons.directions_walk_rounded,
                            label: 'Steps',
                            value: steps,
                            goal: stepGoal > 0 ? stepGoal : 6000,
                            color: _blue,
                            unit: 'steps',
                          ),
                          const SizedBox(height: 10),

                          // Water progress
                          _progressCard(
                            icon: Icons.water_drop_rounded,
                            label: 'Water',
                            value: water,
                            goal: waterGoal > 0 ? waterGoal : 2000,
                            color: const Color(0xFF48B0D5),
                            unit: 'ml',
                          ),
                          const SizedBox(height: 10),

                          // Calories burned (no food)
                          _simpleStatCard(
                            icon: Icons.bolt_rounded,
                            label: 'Calories Burned',
                            value: '$calories kcal',
                            color: _orange,
                          ),
                          const SizedBox(height: 10),

                          // Goals completed today
                          _simpleStatCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Goals Completed Today',
                            value: goalsToday > 0
                                ? '$goalsToday goal${goalsToday > 1 ? 's' : ''}'
                                : 'None yet',
                            color: _green,
                          ),

                          const SizedBox(height: 20),

                          // ── Fitness profile ─────────────────────────────
                          _sectionLabel('Fitness Profile'),
                          const SizedBox(height: 10),
                          _infoCard(children: [
                            if (goal.isNotEmpty)
                              _infoRow(Icons.flag_rounded, 'Goal', goal,
                                  _purple),
                            if (level.isNotEmpty)
                              _infoRow(Icons.bar_chart_rounded,
                                  'Fitness Level', level, _teal),
                            if (activity.isNotEmpty)
                              _infoRow(Icons.sports_score_rounded,
                                  'Preferred Activity', activity, _orange),
                            _infoRow(
                              Icons.calendar_month_rounded,
                              'Member Since',
                              _memberSince(joined),
                              _blue,
                            ),
                            _infoRow(
                              Icons.hourglass_bottom_rounded,
                              'Days on Vigor',
                              _daysSinceLabel(joined),
                              _green,
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Widget helpers ──────────────────────────────────────────────────────────

  Widget _tag(String label, Color color) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700),
    ),
  );

  Widget _sectionLabel(String t) => Text(
    t.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: _textSec,
      letterSpacing: 1.0,
    ),
  );

  Widget _bigStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: _textPri),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                    color: _textSec, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _progressCard({
    required IconData icon,
    required String label,
    required int value,
    required int goal,
    required Color color,
    required String unit,
  }) {
    final pct = (value / goal).clamp(0.0, 1.0);
    final pctLabel = '${(pct * 100).toInt()}%';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _textPri)),
                  Text(
                    '$value / $goal $unit',
                    style: const TextStyle(
                        color: _textSec, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              pctLabel,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ]),
      );

  Widget _infoCard({required List<Widget> children}) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ],
    ),
    child: Column(children: children),
  );

  Widget _infoRow(
      IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: _textSec, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: _textPri,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  String _memberSince(dynamic raw) {
    if (raw == null) return 'Unknown';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is String)    dt = DateTime.tryParse(raw);
    if (dt == null)       return 'Unknown';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}