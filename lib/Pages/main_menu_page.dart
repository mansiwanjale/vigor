import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../session.dart';
import '../main.dart';
import 'workout/workout_home.dart';
import 'Diet.dart';
import 'Community.dart';
import 'Profile.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final String username = Session().currentUsername ?? "Shru_22";

  // ── colors (matching your existing app palette) ──────────────────
  static const Color _bg         = Color(0xFFEAE8E0);
  static const Color _surface    = Color(0xFFFFFFFF);
  static const Color _sage       = Color(0xFFD4E4D4);
  static const Color _sageDark   = Color(0xFFB8CCB8);
  static const Color _sageText   = Color(0xFF3D5C3D);
  static const Color _steel      = Color(0xFF5B7B8F);
  static const Color _teal       = Color(0xFF4CAF8A);
  static const Color _text       = Color(0xFF1A1A1A);
  static const Color _text2      = Color(0xFF555555);
  static const Color _text3      = Color(0xFF999999);

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── HEADER ────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── GREETING ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildGreeting()),

            // ── STORIES ───────────────────────────────────────────
            SliverToBoxAdapter(child: _buildStoriesRow()),

            SliverToBoxAdapter(
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.black.withOpacity(0.07),
                indent: 20,
                endIndent: 20,
              ),
            ),

            // ── NAV GRID ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildNavGrid()),

            // ── TIP OF THE DAY ────────────────────────────────────
            SliverToBoxAdapter(child: _buildTipCard()),

            // ── EXERCISE OF THE DAY ───────────────────────────────
            SliverToBoxAdapter(child: _buildExerciseCard()),

            // ── MOTIVATION BANNER ─────────────────────────────────
            SliverToBoxAdapter(child: _buildMotivationCard()),

            // ── COMMUNITY FEED ────────────────────────────────────
            SliverToBoxAdapter(child: _buildCommunityFeed()),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
      child: Row(
        children: [
          Text(
            'VIGOR',
            style: GoogleFonts.bebasNeue(
              fontSize: 34,
              letterSpacing: 3,
              color: _text,
            ),
          ),
          const Spacer(),
          // notification button
          Stack(
            children: [
              _iconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE05C5C),
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          _iconButton(icon: Icons.search_rounded, onTap: () {}),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: _text2),
      ),
    );
  }

  // ── GREETING ──────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greeting,
              style: const TextStyle(fontSize: 14, color: _text3)),
          const SizedBox(height: 2),
          Text(
            '$username 🔥',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: _text,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── STORIES ───────────────────────────────────────────────────────
  static const _stories = [
    _StoryData('Your Story', '➕', seen: false, isAdd: true),
    _StoryData('Chest Day',  '🏋️', seen: false),
    _StoryData('Protein Meals', '🥗', seen: false),
    _StoryData('Mobility',  '🧘', seen: false),
    _StoryData('Recovery',  '💤', seen: true),
    _StoryData('HIIT',      '⚡', seen: true),
  ];

  Widget _buildStoriesRow() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _buildStoryItem(_stories[i]),
      ),
    );
  }

  Widget _buildStoryItem(_StoryData s) {
    return GestureDetector(
      onTap: s.isAdd ? null : () {},
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.isAdd
                  ? Colors.transparent
                  : s.seen
                  ? const Color(0xFFCCCCCC)
                  : _teal,
              border: s.isAdd
                  ? Border.all(
                color: _text3,
                width: 1.5,
                style: BorderStyle.solid,
              )
                  : null,
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _bg,
              ),
              child: Center(
                child: Text(s.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 62,
            child: Text(
              s.label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, color: _text2),
            ),
          ),
        ],
      ),
    );
  }

  // ── NAV GRID ──────────────────────────────────────────────────────
  Widget _buildNavGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              "What's your focus?",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _NavTile(
                emoji: '💪',
                title: 'Workout',
                subtitle: '4 sessions this week',
                bgColor: _steel,
                titleColor: Colors.white,
                subtitleColor: Colors.white70,
                onTap: () => _open(const WorkoutHome()),
              ),
              _NavTile(
                emoji: '🥗',
                title: 'Diet',
                subtitle: '250 kcal under today',
                bgColor: _sage,
                titleColor: _sageText,
                subtitleColor: _sageText,
                onTap: () => _open(DietPage()),
              ),
              _NavTile(
                emoji: '👥',
                title: 'Community',
                subtitle: '5 friends active today',
                bgColor: _surface,
                badge: '5 new',
                onTap: () => _open(const Community()),
              ),
              _NavTile(
                emoji: '👤',
                title: 'Profile',
                subtitle: 'Level 3 · Intermediate',
                bgColor: _surface,
                onTap: () => _open(ProfilePage(username: username)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TIP OF THE DAY ────────────────────────────────────────────────
  Widget _buildTipCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _sage,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💧', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'TIP OF THE DAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: _sageText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Drink water before, during, and after your workout to stay hydrated and perform better.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF2A3D2A),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EXERCISE OF THE DAY ───────────────────────────────────────────
  Widget _buildExerciseCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exercise of the Day',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _text)),
                GestureDetector(
                  onTap: () {},
                  child: const Text('See all',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _steel)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                        child: Text('🏋️',
                            style: TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('RECOMMENDED FOR YOU',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: _text3)),
                        SizedBox(height: 3),
                        Text('Push-Ups',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _text)),
                        SizedBox(height: 2),
                        Text('Chest · Triceps · Shoulders',
                            style:
                            TextStyle(fontSize: 12, color: _text3)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 6),
                    decoration: BoxDecoration(
                      color: _sage,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('4 × 15',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _sageText)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MOTIVATION BANNER ─────────────────────────────────────────────
  Widget _buildMotivationCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _steel,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '"Push yourself because no one else is going to do it for you."',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap for today\'s motivation →',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text('❝',
                  style: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      height: 1)),
            ],
          ),
        ),
      ),
    );
  }

  // ── COMMUNITY FEED ────────────────────────────────────────────────
  Widget _buildCommunityFeed() {
    const feedItems = [
      _FeedItem('AR', 'Aryan completed Chest Workout 💪', '2m',
          Color(0xFFDDE8F0), Color(0xFF3D6080)),
      _FeedItem('SN', 'Sneha hit 10K steps today 🔥', '14m',
          Color(0xFFD4E4D4), Color(0xFF3D5C3D)),
      _FeedItem('RH', 'Rahul started a new transformation journey',
          '1h', Color(0xFFF0E8D4), Color(0xFF7A5C20)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Community Feed',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _text)),
                GestureDetector(
                  onTap: () => _open(const Community()),
                  child: const Text('See all',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _steel)),
                ),
              ],
            ),
          ),
          ...feedItems.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: f.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(f.initials,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: f.avatarFg)),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(f.text,
                        style: const TextStyle(
                            fontSize: 13,
                            color: _text2,
                            height: 1.4)),
                  ),
                  Text(f.time,
                      style: const TextStyle(
                          fontSize: 11, color: _text3)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ── DATA MODELS ───────────────────────────────────────────────────────

class _StoryData {
  final String label;
  final String emoji;
  final bool seen;
  final bool isAdd;
  const _StoryData(this.label, this.emoji,
      {this.seen = false, this.isAdd = false});
}

class _FeedItem {
  final String initials;
  final String text;
  final String time;
  final Color avatarBg;
  final Color avatarFg;
  const _FeedItem(
      this.initials, this.text, this.time, this.avatarBg, this.avatarFg);
}

// ── NAV TILE WIDGET ───────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color titleColor;
  final Color subtitleColor;
  final String? badge;
  final VoidCallback onTap;

  const _NavTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.onTap,
    this.titleColor = const Color(0xFF1A1A1A),
    this.subtitleColor = const Color(0xFF999999),
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: subtitleColor.withOpacity(
                            bgColor == const Color(0xFF5B7B8F)
                                ? 0.65
                                : 0.8))),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E4D4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D5C3D))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}