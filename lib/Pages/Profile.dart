import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigor/Auth/login_page.dart' as auth_login;
import 'package:vigor/Pages/Notifications.dart';
import '../main.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Avatar preset model
// ─────────────────────────────────────────────────────────────────────────────
class AvatarPreset {
  final String id;
  final String label;
  final Color bgColor;
  final Color shirtColor;
  final IconData icon;

  const AvatarPreset({
    required this.id,
    required this.label,
    required this.bgColor,
    required this.shirtColor,
    required this.icon,
  });
}

const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset(
      id: 'runner',
      label: 'Runner',
      bgColor: Color(0xFFDCEEF5),
      shirtColor: Color(0xFF5C7C8A),
      icon: Icons.directions_run_rounded),
  AvatarPreset(
      id: 'lifter',
      label: 'Lifter',
      bgColor: Color(0xFFFCE4EC),
      shirtColor: Color(0xFFE07A5F),
      icon: Icons.fitness_center_rounded),
  AvatarPreset(
      id: 'yogi',
      label: 'Yogi',
      bgColor: Color(0xFFE8F5E9),
      shirtColor: Color(0xFF6FBF9F),
      icon: Icons.self_improvement_rounded),
  AvatarPreset(
      id: 'cyclist',
      label: 'Cyclist',
      bgColor: Color(0xFFFFF8E1),
      shirtColor: Color(0xFFFFB300),
      icon: Icons.directions_bike_rounded),
  AvatarPreset(
      id: 'swimmer',
      label: 'Swimmer',
      bgColor: Color(0xFFE3F2FD),
      shirtColor: Color(0xFF1976D2),
      icon: Icons.pool_rounded),
  AvatarPreset(
      id: 'ninja',
      label: 'Ninja',
      bgColor: Color(0xFFEDE7F6),
      shirtColor: Color(0xFF6A1B9A),
      icon: Icons.sports_martial_arts_rounded),
  AvatarPreset(
      id: 'hiker',
      label: 'Hiker',
      bgColor: Color(0xFFF1F8E9),
      shirtColor: Color(0xFF558B2F),
      icon: Icons.hiking_rounded),
  AvatarPreset(
      id: 'boxer',
      label: 'Boxer',
      bgColor: Color(0xFFFFEBEE),
      shirtColor: Color(0xFFC62828),
      icon: Icons.sports_mma_rounded),
  AvatarPreset(
      id: 'dancer',
      label: 'Dancer',
      bgColor: Color(0xFFFCE4EC),
      shirtColor: Color(0xFFAD1457),
      icon: Icons.music_note_rounded),
];

AvatarPreset _defaultPresetForAge(int age, String goal) {
  final g = goal.toLowerCase();
  if (g.contains('run') || g.contains('cardio'))
    return kAvatarPresets.firstWhere((p) => p.id == 'runner');
  if (g.contains('cycl') || g.contains('bike'))
    return kAvatarPresets.firstWhere((p) => p.id == 'cyclist');
  if (g.contains('swim'))
    return kAvatarPresets.firstWhere((p) => p.id == 'swimmer');
  if (g.contains('yoga') || g.contains('flex') || g.contains('stretch'))
    return kAvatarPresets.firstWhere((p) => p.id == 'yogi');
  if (g.contains('muscle') ||
      g.contains('strength') ||
      g.contains('lift') ||
      g.contains('bulk'))
    return kAvatarPresets.firstWhere((p) => p.id == 'lifter');
  if (age < 18) return kAvatarPresets.firstWhere((p) => p.id == 'ninja');
  if (age < 30) return kAvatarPresets.firstWhere((p) => p.id == 'runner');
  if (age < 45) return kAvatarPresets.firstWhere((p) => p.id == 'lifter');
  if (age < 60) return kAvatarPresets.firstWhere((p) => p.id == 'hiker');
  return kAvatarPresets.firstWhere((p) => p.id == 'yogi');
}
final VigorSettings vigorSettings = VigorSettings();
// ─────────────────────────────────────────────────────────────────────────────
// VigorSettings ChangeNotifier (singleton)
// All settings are persisted in SharedPreferences and exposed via getters.
// Dark mode drives the global theme via ChangeNotifierProvider in main.dart.
// ─────────────────────────────────────────────────────────────────────────────
class VigorSettings extends ChangeNotifier {
  bool _darkMode = false;
  bool _privacyMode = false;
  String _units = 'Metric'; // 'Metric' | 'Imperial'

  // Notification / tracking flags
  bool _notifications = true;
  bool _waterReminder = true;
  bool _stepTracking = true;
  bool _calorieAlerts = false;
  bool _weeklyReport = true;

  bool get darkMode => _darkMode;
  bool get privacyMode => _privacyMode;
  String get units => _units;

  bool get notifications => _notifications;
  bool get waterReminder => _waterReminder;
  bool get stepTracking => _stepTracking;
  bool get calorieAlerts => _calorieAlerts;
  bool get weeklyReport => _weeklyReport;

  // Derived helpers
  String get weightUnit => _units == 'Metric' ? 'kg' : 'lbs';
  String get heightUnit => _units == 'Metric' ? 'cm' : 'ft';
  String get distanceUnit => _units == 'Metric' ? 'km' : 'mi';
  String get waterUnit => _units == 'Metric' ? 'ml' : 'fl oz';

  VigorSettings() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _darkMode = p.getBool('darkMode') ?? false;
    _privacyMode = p.getBool('privacyMode') ?? false;
    _units = p.getString('units') ?? 'Metric';
    _notifications = p.getBool('notifications') ?? true;
    _waterReminder = p.getBool('waterReminder') ?? true;
    _stepTracking = p.getBool('stepTracking') ?? true;
    _calorieAlerts = p.getBool('calorieAlerts') ?? false;
    _weeklyReport = p.getBool('weeklyReport') ?? true;
    notifyListeners();
  }

  Future<void> _save(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is bool) p.setBool(key, value);
    if (value is String) p.setString(key, value);
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    notifyListeners();
    _save('darkMode', v);
  }

  Future<void> setPrivacyMode(bool v) async {
    _privacyMode = v;
    notifyListeners();
    _save('privacyMode', v);
  }

  Future<void> setUnits(String v) async {
    _units = v;
    notifyListeners();
    _save('units', v);
  }

  Future<void> setNotifications(bool v) async {
    _notifications = v;
    notifyListeners();
    _save('notifications', v);
  }

  Future<void> setWaterReminder(bool v) async {
    _waterReminder = v;
    notifyListeners();
    _save('waterReminder', v);
  }

  Future<void> setStepTracking(bool v) async {
    _stepTracking = v;
    notifyListeners();
    _save('stepTracking', v);
  }

  Future<void> setCalorieAlerts(bool v) async {
    _calorieAlerts = v;
    notifyListeners();
    _save('calorieAlerts', v);
  }

  Future<void> setWeeklyReport(bool v) async {
    _weeklyReport = v;
    notifyListeners();
    _save('weeklyReport', v);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Page
// ─────────────────────────────────────────────────────────────────────────────
class SettingsPage extends StatefulWidget {
  final String username;
  const SettingsPage({super.key, required this.username});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _waterGoalCtrl = TextEditingController();
  final _stepGoalCtrl = TextEditingController();

  // We read/write directly from/to the VigorSettings singleton
  // so the state is always in sync across the app.

  @override
  void initState() {
    super.initState();
    _loadGoals();
    vigorSettings.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    vigorSettings.removeListener(_rebuild);
    _waterGoalCtrl.dispose();
    _stepGoalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final doc = await FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(widget.username)
        .get();
    final data = doc.data() ?? {};
    if (!mounted) return;
    setState(() {
      _stepGoalCtrl.text =
          (data['stepGoal'] ?? prefs.getString('stepGoal') ?? '6000')
              .toString();
      _waterGoalCtrl.text =
          (data['waterGoal'] ?? prefs.getString('waterGoal') ?? '2000')
              .toString();
    });
  }

  Future<void> _saveGoalsToFirestore() async {
    final ref = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(widget.username);
    await ref.set({
      'stepGoal': int.tryParse(_stepGoalCtrl.text) ?? 6000,
      'waterGoal': int.tryParse(_waterGoalCtrl.text) ?? 2000,
    }, SetOptions(merge: true));
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('stepGoal', _stepGoalCtrl.text);
    prefs.setString('waterGoal', _waterGoalCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Goals saved! ✓'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF4CAF8E)),
      );
    }
  }

  Future<void> _clearActivityData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text('Clear Activity Data',
            style: TextStyle(color: _text, fontWeight: FontWeight.w700)),
        content: Text("This will reset today's water intake. Are you sure?",
            style: TextStyle(color: _sub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear',
                  style: TextStyle(color: Color(0xFFE07A5F)))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(widget.username)
          .set({'water': 0}, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Activity data cleared.'),
              duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text('Delete Account',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently delete your account and all data. This cannot be undone.',
            style: TextStyle(color: _sub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(widget.username)
            .delete();
        await FirebaseAuth.instance.currentUser?.delete();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => const auth_login.LoginPage()),
                  (r) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  // ── Theme helpers ─────────────────────────────────────────
  Color get _bg =>
      vigorSettings.darkMode ? const Color(0xFF1A1A2E) : AppColors.background;
  Color get _card =>
      vigorSettings.darkMode ? const Color(0xFF252540) : AppColors.white;
  Color get _text =>
      vigorSettings.darkMode ? Colors.white : AppColors.textPrimary;
  Color get _sub =>
      vigorSettings.darkMode ? Colors.white54 : AppColors.textSecondary;
  Color get _inputFill =>
      vigorSettings.darkMode ? const Color(0xFF1A1A2E) : AppColors.background;

  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
    child: Text(t,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _sub,
            letterSpacing: 1.1)),
  );

  Widget _tile({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required Widget trailing,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _text)),
            subtitle: Text(sublabel,
                style: TextStyle(fontSize: 11, color: _sub)),
            trailing: trailing,
          ),
        ),
      );

  Widget _buildUnitToggle() {
    final isMetric = vigorSettings.units == 'Metric';
    return GestureDetector(
      onTap: () {
        vigorSettings.setUnits(isMetric ? 'Imperial' : 'Metric');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF6FBF9F).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(vigorSettings.units,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6FBF9F))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = vigorSettings.darkMode;
    final isPrivate = vigorSettings.privacyMode;
    final unitLabel = vigorSettings.units == 'Metric'
        ? 'kg · cm · ml · km'
        : 'lbs · ft · fl oz · mi';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Settings',
            style: TextStyle(
                color: _text, fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: IconThemeData(color: _text),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          // ── Appearance ─────────────────────────────────────
          _sectionHeader('APPEARANCE'),
          _tile(
            icon: isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            label: isDark ? 'Light Mode' : 'Dark Mode',
            sublabel: isDark
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            color: const Color(0xFF5C7C8A),
            trailing: Switch.adaptive(
              value: isDark,
              activeColor: AppColors.greenDark,
              // setDarkMode calls notifyListeners() which updates
              // the ChangeNotifierProvider in main.dart → rebuilds
              // MaterialApp with the new themeMode. All pages respond.
              onChanged: (v) => vigorSettings.setDarkMode(v),
            ),
          ),
          _tile(
            icon: Icons.straighten_rounded,
            label: 'Units',
            sublabel: unitLabel,
            color: const Color(0xFF6FBF9F),
            trailing: _buildUnitToggle(),
          ),

          // ── Notifications ───────────────────────────────────
          _sectionHeader('NOTIFICATIONS'),
          _tile(
            icon: Icons.notifications_rounded,
            label: 'Push Notifications',
            sublabel: 'Workout reminders & updates',
            color: const Color(0xFFE07A5F),
            trailing: Switch.adaptive(
              value: vigorSettings.notifications,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setNotifications(v),
            ),
          ),
          _tile(
            icon: Icons.water_drop_rounded,
            label: 'Water Reminders',
            // Show a hint when disabled
            sublabel: vigorSettings.waterReminder
                ? 'Get reminded to stay hydrated'
                : 'Water notifications disabled',
            color: const Color(0xFF5C7C8A),
            trailing: Switch.adaptive(
              value: vigorSettings.waterReminder,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setWaterReminder(v),
            ),
          ),
          _tile(
            icon: Icons.local_fire_department_rounded,
            label: 'Calorie Alerts',
            sublabel: vigorSettings.calorieAlerts
                ? 'Alert when daily target is exceeded'
                : 'Calorie alerts disabled',
            color: const Color(0xFFE07A5F),
            trailing: Switch.adaptive(
              value: vigorSettings.calorieAlerts,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setCalorieAlerts(v),
            ),
          ),
          _tile(
            icon: Icons.bar_chart_rounded,
            label: 'Weekly Report',
            sublabel: vigorSettings.weeklyReport
                ? 'Summary of your weekly activity'
                : 'Weekly reports disabled',
            color: const Color(0xFF6FBF9F),
            trailing: Switch.adaptive(
              value: vigorSettings.weeklyReport,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setWeeklyReport(v),
            ),
          ),

          // ── Activity Tracking ───────────────────────────────
          _sectionHeader('ACTIVITY TRACKING'),
          _tile(
            icon: Icons.directions_walk_rounded,
            label: 'Step Tracking',
            sublabel: vigorSettings.stepTracking
                ? 'Count steps using pedometer'
                : 'Step tracking is OFF',
            color: const Color(0xFF6FBF9F),
            trailing: Switch.adaptive(
              value: vigorSettings.stepTracking,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setStepTracking(v),
            ),
          ),

          // Daily goals card
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF5C7C8A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.tune_rounded,
                          color: Color(0xFF5C7C8A), size: 18)),
                  const SizedBox(width: 10),
                  Text('Daily Goals',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _text)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: TextField(
                        controller: _stepGoalCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: _text, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Step Goal',
                          prefixIcon: const Icon(Icons.directions_walk_rounded,
                              size: 16, color: AppColors.textSecondary),
                          labelStyle: TextStyle(color: _sub, fontSize: 12),
                          filled: true,
                          fillColor: _inputFill,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                      )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                        controller: _waterGoalCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: _text, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Water Goal (${vigorSettings.waterUnit})',
                          prefixIcon: const Icon(Icons.water_drop_rounded,
                              size: 16, color: AppColors.textSecondary),
                          labelStyle: TextStyle(color: _sub, fontSize: 12),
                          filled: true,
                          fillColor: _inputFill,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                      )),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _saveGoalsToFirestore,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenDark,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0),
                    child: const Text('Save Goals',
                        style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),

          // ── Privacy & Security ──────────────────────────────
          _sectionHeader('PRIVACY & SECURITY'),
          _tile(
            icon: Icons.lock_rounded,
            label: 'Privacy Mode',
            sublabel: isPrivate
                ? 'Stats hidden — tap to reveal'
                : 'Your stats are visible to you',
            color: const Color(0xFF9B8EA8),
            trailing: Switch.adaptive(
              value: isPrivate,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setPrivacyMode(v),
            ),
          ),
          _tile(
            icon: Icons.delete_outline_rounded,
            label: 'Clear Activity Data',
            sublabel: "Reset today's water intake",
            color: const Color(0xFFE07A5F),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
            onTap: _clearActivityData,
          ),

          // ── About ───────────────────────────────────────────
          _sectionHeader('ABOUT'),
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFF5C7C8A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF5C7C8A), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About Vigor',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _text)),
                        Text('Version 1.0.0',
                            style: TextStyle(fontSize: 11, color: _sub)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'Vigor is your all-in-one fitness companion — designed to help you track workouts, monitor nutrition, stay hydrated, and build healthy habits every day. Whether you\'re a beginner or an athlete, Vigor adapts to your goals and keeps you motivated.',
                    style: TextStyle(fontSize: 12, color: _sub, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🏋️ Track workouts  •  🥗 Log meals  •  💧 Stay hydrated  •  👟 Count steps',
                    style: TextStyle(
                        fontSize: 11,
                        color: _sub,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          _tile(
            icon: Icons.star_outline_rounded,
            label: 'Rate Vigor',
            sublabel: 'Enjoying the app? Leave a review!',
            color: const Color(0xFFFFB300),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () async {
              final Uri url = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.example.vigor',
              );

              if (await canLaunchUrl(url)) {
                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open Play Store'),
                    ),
                  );
                }
              }
            },
          ),

          _tile(
            icon: Icons.share_rounded,
            label: 'Share with Friends',
            sublabel: 'Invite friends to join Vigor',
            color: const Color(0xFF6FBF9F),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () async {
              await Share.share(
                '🔥 Check out Vigor Fitness App!\n\nTrack workouts, hydration, calories, and fitness goals easily.\n\nDownload now:\nhttps://play.google.com/store/apps/details?id=com.example.vigor',
                subject: 'Vigor Fitness App',
              );
            },
          ),

          // ── Account ─────────────────────────────────────────
          _sectionHeader('ACCOUNT'),
          _tile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            sublabel: 'Log out of your account',
            color: const Color(0xFFE07A5F),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const auth_login.LoginPage()),
                        (r) => false);
              }
            },
          ),
          _tile(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Account',
            sublabel: 'Permanently remove your data',
            color: Colors.red,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Page
// ─────────────────────────────────────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  final String username;
  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  int _liveSteps = 0;
  int _stepBaseline = -1;
  String _pedestrianStatus = 'stopped';

  @override
  void initState() {
    super.initState();
    // Start pedometer only if step tracking is currently enabled
    if (vigorSettings.stepTracking) {
      _initPedometer();
    }
    // Listen for settings changes (e.g. user toggles step tracking)
    vigorSettings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
    // React to step tracking toggle
    if (vigorSettings.stepTracking) {
      if (_stepSub == null) _initPedometer();
    } else {
      _stopPedometer();
    }
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return;
    _stepSub = Pedometer.stepCountStream.listen(
          (e) {
        if (!mounted) return;
        // Only process if step tracking is still on
        if (!vigorSettings.stepTracking) return;
        setState(() {
          if (_stepBaseline == -1) _stepBaseline = e.steps;
          _liveSteps = (e.steps - _stepBaseline).clamp(0, 999999);
        });
      },
      onError: (e) => debugPrint('Step error: $e'),
    );
    _statusSub = Pedometer.pedestrianStatusStream.listen(
          (e) {
        if (mounted && vigorSettings.stepTracking) {
          setState(() => _pedestrianStatus = e.status);
        }
      },
      onError: (e) => debugPrint('Status error: $e'),
    );
  }

  void _stopPedometer() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _stepSub = null;
    _statusSub = null;
    setState(() {
      _liveSteps = 0;
      _stepBaseline = -1;
      _pedestrianStatus = 'stopped';
    });
  }

  @override
  void dispose() {
    vigorSettings.removeListener(_onSettingsChanged);
    _stepSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  int _parse(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _distanceString(double km) {
    if (vigorSettings.units == 'Imperial') {
      return '${(km * 0.621371).toStringAsFixed(2)} mi';
    }
    return '${km.toStringAsFixed(2)} km';
  }

  String _waterDisplay(int ml) {
    if (vigorSettings.units == 'Imperial') {
      return '${(ml * 0.033814).toStringAsFixed(0)} fl oz';
    }
    return '$ml ml';
  }

  String _weightDisplay(dynamic w) {
    if (w == null || w.toString().isEmpty) return '—';
    final kg = double.tryParse(w.toString()) ?? 0;
    if (vigorSettings.units == 'Imperial') {
      return '${(kg * 2.20462).toStringAsFixed(1)} lbs';
    }
    return '${kg.toStringAsFixed(1)} kg';
  }

  String _heightDisplay(dynamic h) {
    if (h == null || h.toString().isEmpty) return '—';
    final cm = double.tryParse(h.toString()) ?? 0;
    if (vigorSettings.units == 'Imperial') {
      final totalIn = (cm / 2.54).round();
      final ft = totalIn ~/ 12;
      final inches = totalIn % 12;
      return "$ft'$inches\"";
    }
    return '${cm.toStringAsFixed(0)} cm';
  }

  void _showAvatarOptions(BuildContext context, DocumentReference ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.88,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Column(children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.inputField,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Choose Your Avatar',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                const Text('Pick a character or upload your photo',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 14),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _sheetLabel('Illustrated Characters'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: kAvatarPresets.length,
                    itemBuilder: (_, i) {
                      final p = kAvatarPresets[i];
                      return GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.set(
                              {'avatarBase64': '', 'avatarPresetId': p.id},
                              SetOptions(merge: true));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: p.bgColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: p.shirtColor.withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        color: p.shirtColor,
                                        shape: BoxShape.circle),
                                    child: Icon(p.icon,
                                        color: Colors.white, size: 24)),
                                const SizedBox(height: 8),
                                Text(p.label,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: p.shirtColor)),
                              ]),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _sheetLabel('Upload Photo'),
                  const SizedBox(height: 12),
                  _photoOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take a Photo',
                      sublabel: 'Use your camera',
                      color: AppColors.blue,
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickAndUpload(ImageSource.camera, ref);
                      }),
                  const SizedBox(height: 10),
                  _photoOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Choose from Gallery',
                      sublabel: 'Pick from your photos',
                      color: AppColors.greenDark,
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickAndUpload(ImageSource.gallery, ref);
                      }),
                  const SizedBox(height: 10),
                  _photoOption(
                      icon: Icons.refresh_rounded,
                      label: 'Reset to Default',
                      sublabel: 'Auto-select based on your age & goal',
                      color: const Color(0xFFE07A5F),
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.set(
                            {'avatarBase64': '', 'avatarPresetId': ''},
                            SetOptions(merge: true));
                      }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetLabel(String t) => Text(t,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.6));

  Widget _photoOption(
      {required IconData icon,
        required String label,
        required String sublabel,
        required Color color,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            Text(sublabel,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ]),
          const Spacer(),
          Icon(Icons.chevron_right_rounded,
              color: color.withOpacity(0.4), size: 20),
        ]),
      ),
    );
  }

  Future<void> _pickAndUpload(
      ImageSource source, DocumentReference ref) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
        source: source, maxWidth: 400, maxHeight: 400, imageQuality: 70);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    await ref.set({'avatarBase64': base64Encode(bytes), 'avatarPresetId': ''},
        SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = vigorSettings.privacyMode;
    final userProfileRef = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(widget.username);
    final usersRef =
    FirebaseFirestore.instance.collection('users').doc(widget.username);

    final profileFields = [
      'name', 'age', 'gender', 'weight', 'height',
      'goal', 'city', 'fitnessLevel', 'preferredActivity',
      'weeklyGoalDays', 'bio',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, authSnap) {
          final authData = authSnap.hasData
              ? (authSnap.data!.data() as Map<String, dynamic>? ?? {})
              : <String, dynamic>{};

          return StreamBuilder<DocumentSnapshot>(
            stream: userProfileRef.snapshots(),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) {
                return const Center(
                    child:
                    CircularProgressIndicator(color: AppColors.green));
              }

              final profileData =
                  profileSnap.data!.data() as Map<String, dynamic>? ?? {};
              final merged = {...profileData, ...authData};

              final String displayName =
              merged['name']?.toString().isNotEmpty == true
                  ? merged['name']
                  : widget.username;
              final String displayCity =
              merged['city']?.toString().isNotEmpty == true
                  ? merged['city']
                  : 'No city set';
              final String displayGoal =
              merged['goal']?.toString().isNotEmpty == true
                  ? merged['goal']
                  : '';
              final String displayBio =
              merged['bio']?.toString().isNotEmpty == true
                  ? merged['bio']
                  : '';
              final String displayFitnessLevel =
              merged['fitnessLevel']?.toString().isNotEmpty == true
                  ? merged['fitnessLevel']
                  : '';
              final String displayActivity =
              merged['preferredActivity']?.toString().isNotEmpty == true
                  ? merged['preferredActivity']
                  : '';

              final int age = _parse(merged['age']);
              final String gender =
                  merged['gender']?.toString().toLowerCase() ?? '';

              final String avatarBase64 =
                  profileData['avatarBase64']?.toString() ?? '';
              final String avatarPresetId =
                  profileData['avatarPresetId']?.toString() ?? '';

              AvatarPreset resolvedPreset = avatarPresetId.isNotEmpty
                  ? (kAvatarPresets.any((p) => p.id == avatarPresetId)
                  ? kAvatarPresets
                  .firstWhere((p) => p.id == avatarPresetId)
                  : _defaultPresetForAge(age, displayGoal))
                  : _defaultPresetForAge(age, displayGoal);

              int filled = profileFields
                  .where((f) =>
              merged[f] != null && merged[f].toString().isNotEmpty)
                  .length;
              double completionRatio = filled / profileFields.length;
              int percent = (completionRatio * 100).toInt();
              bool isComplete = percent >= 100;

              final String initials = displayName
                  .trim()
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join();

              int stepGoal = _parse(profileData['stepGoal']);
              int safeGoal = stepGoal == 0 ? 6000 : stepGoal;

              int water = _parse(profileData['water']);
              int waterGoal = _parse(profileData['waterGoal']);
              int safeWaterGoal = waterGoal == 0 ? 2000 : waterGoal;

              double distanceKm = _liveSteps * 0.000762;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('workout_history')
                    .where('username', isEqualTo: widget.username)
                    .snapshots(),
                builder: (context, workoutSnap) {
                  int totalWorkouts = 0;
                  int totalBurned = 0;
                  int streak = 0;
                  final now = DateTime.now();

                  if (workoutSnap.hasData) {
                    final dates = <DateTime>{};
                    for (var d in workoutSnap.data!.docs) {
                      final m = d.data() as Map<String, dynamic>;
                      totalWorkouts++;
                      totalBurned += _parse(m['calories'] ??
                          m['burned'] ??
                          m['caloriesBurned']);
                      final ts = m['timestamp'];
                      if (ts is Timestamp) {
                        final dt = ts.toDate();
                        dates.add(DateTime(dt.year, dt.month, dt.day));
                      }
                    }
                    final sorted = dates.toList()
                      ..sort((a, b) => b.compareTo(a));
                    DateTime check =
                    DateTime(now.year, now.month, now.day);
                    for (final d in sorted) {
                      if (d == check ||
                          d == check.subtract(const Duration(days: 1))) {
                        streak++;
                        check =
                            check.subtract(const Duration(days: 1));
                      } else {
                        break;
                      }
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('meals')
                        .where('userId', isEqualTo: widget.username)
                        .snapshots(),
                    builder: (context, mealSnap) {
                      int totalGained = 0;
                      if (mealSnap.hasData) {
                        for (var d in mealSnap.data!.docs) {
                          final m = d.data() as Map<String, dynamic>;
                          totalGained +=
                              _parse(m['calories'] ?? m['gained']);
                        }
                      }

                      int netCalories = totalGained - totalBurned;
                      String mask(String v) => isPrivate ? '••••' : v;

                      return CustomScrollView(
                        slivers: [
                          // ── Header ──────────────────────────
                          SliverToBoxAdapter(
                            child: Container(
                              color: AppColors.blue,
                              padding: const EdgeInsets.fromLTRB(
                                  24, 56, 24, 24),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showAvatarOptions(
                                            context, userProfileRef),
                                        child: _AvatarWithRing(
                                          initials: initials,
                                          isFemale: gender == 'female' ||
                                              gender == 'f',
                                          avatarBase64: avatarBase64,
                                          resolvedPreset: resolvedPreset,
                                          completionRatio: completionRatio,
                                          percent: percent,
                                          isComplete: isComplete,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(displayName,
                                                style: const TextStyle(
                                                    color: AppColors.white,
                                                    fontSize: 20,
                                                    fontWeight:
                                                    FontWeight.w800,
                                                    letterSpacing: -0.5)),
                                            if (displayBio
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(displayBio,
                                                  style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                      fontStyle: FontStyle
                                                          .italic),
                                                  maxLines: 2,
                                                  overflow: TextOverflow
                                                      .ellipsis),
                                            ],
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              const Icon(
                                                  Icons
                                                      .location_on_rounded,
                                                  color: Colors.white54,
                                                  size: 12),
                                              const SizedBox(width: 3),
                                              Flexible(
                                                  child: Text(displayCity,
                                                      style: const TextStyle(
                                                          color:
                                                          Colors.white54,
                                                          fontSize: 12),
                                                      overflow: TextOverflow
                                                          .ellipsis)),
                                              if (displayActivity
                                                  .isNotEmpty) ...[
                                                const SizedBox(width: 10),
                                                const Icon(
                                                    Icons
                                                        .sports_score_rounded,
                                                    color: Colors.white54,
                                                    size: 12),
                                                const SizedBox(width: 3),
                                                Flexible(
                                                    child: Text(
                                                        displayActivity,
                                                        style: const TextStyle(
                                                            color: Colors
                                                                .white54,
                                                            fontSize: 12),
                                                        overflow:
                                                        TextOverflow
                                                            .ellipsis)),
                                              ],
                                            ]),
                                            const SizedBox(height: 8),
                                            // Only show pedometer chip when tracking is on
                                            if (vigorSettings.stepTracking)
                                              _PedometerChip(
                                                  status: _pedestrianStatus,
                                                  liveSteps: _liveSteps)
                                            else
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      20),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                  MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .directions_walk_rounded,
                                                        color: Colors.white38,
                                                        size: 13),
                                                    SizedBox(width: 5),
                                                    Text(
                                                        'Step tracking off',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .white38,
                                                            fontSize: 11,
                                                            fontWeight:
                                                            FontWeight
                                                                .w600)),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Action buttons
                                      Column(children: [
                                        _headerIconBtn(
                                            icon: Icons.edit_rounded,
                                            onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        EditProfilePage(
                                                            username: widget
                                                                .username)))),
                                        const SizedBox(height: 8),
                                        _headerIconBtn(
                                            icon: Icons
                                                .notifications_rounded,
                                            onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        ActivityPage(
                                                            username: widget
                                                                .username)))),
                                        const SizedBox(height: 8),
                                        _headerIconBtn(
                                            icon: Icons.settings_rounded,
                                            onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        SettingsPage(
                                                            username: widget
                                                                .username)))),
                                      ]),
                                    ],
                                  ),
                                  if (displayFitnessLevel.isNotEmpty ||
                                      displayGoal.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Wrap(spacing: 8, children: [
                                      if (displayFitnessLevel.isNotEmpty)
                                        _headerTag(Icons.bar_chart_rounded,
                                            displayFitnessLevel),
                                      if (displayGoal.isNotEmpty)
                                        _headerTag(Icons.flag_rounded,
                                            displayGoal),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // ── Body ─────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // Body metrics
                                  if (merged['weight'] != null ||
                                      merged['height'] != null) ...[
                                    Row(children: [
                                      if (merged['weight'] != null)
                                        _metricChip(
                                            Icons.monitor_weight_rounded,
                                            _weightDisplay(
                                                merged['weight']),
                                            'Weight',
                                            const Color(0xFF6FBF9F)),
                                      if (merged['weight'] != null &&
                                          merged['height'] != null)
                                        const SizedBox(width: 10),
                                      if (merged['height'] != null)
                                        _metricChip(
                                            Icons.height_rounded,
                                            _heightDisplay(
                                                merged['height']),
                                            'Height',
                                            const Color(0xFF5C7C8A)),
                                    ]),
                                    const SizedBox(height: 16),
                                  ],

                                  // Quick stat tiles
                                  Row(children: [
                                    _statTile(
                                        'Total Workouts',
                                        mask('$totalWorkouts'),
                                        Icons.fitness_center_rounded,
                                        const Color(0xFF5C7C8A)),
                                    const SizedBox(width: 10),
                                    _statTile(
                                        'Streak',
                                        mask('$streak days'),
                                        Icons.local_fire_department_rounded,
                                        const Color(0xFFE07A5F)),
                                  ]),

                                  const SizedBox(height: 24),

                                  // Today's Steps
                                  _sectionTitle("Today's Steps"),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius:
                                        BorderRadius.circular(20)),
                                    child: vigorSettings.stepTracking
                                        ? Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          _iconBox(
                                            icon: _pedestrianStatus ==
                                                'walking'
                                                ? Icons
                                                .directions_walk_rounded
                                                : Icons
                                                .accessibility_new_rounded,
                                            color: const Color(
                                                0xFF5C7C8A),
                                            bg: const Color(
                                                0xFFDCEEF5),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                    mask('$_liveSteps steps'),
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                        FontWeight
                                                            .w700,
                                                        color: AppColors
                                                            .textPrimary)),
                                                Text(
                                                    'Goal: $safeGoal steps · ${_distanceString(distanceKm)}',
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            isPrivate
                                                ? '••%'
                                                : '${((_liveSteps / safeGoal) * 100).clamp(0, 100).toInt()}%',
                                            style: const TextStyle(
                                                color:
                                                Color(0xFF5C7C8A),
                                                fontWeight:
                                                FontWeight.w700,
                                                fontSize: 16),
                                          ),
                                        ]),
                                        const SizedBox(height: 14),
                                        _progressBar(
                                            value: isPrivate
                                                ? 0
                                                : (_liveSteps /
                                                safeGoal)
                                                .clamp(0.0, 1.0),
                                            color: const Color(
                                                0xFF5C7C8A)),
                                        const SizedBox(height: 10),
                                        Text(
                                          _pedestrianStatus ==
                                              'walking'
                                              ? '🚶 You\'re walking!'
                                              : '💤 Standing still',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: _pedestrianStatus ==
                                                  'walking'
                                                  ? AppColors.greenDark
                                                  : AppColors
                                                  .textSecondary,
                                              fontWeight:
                                              FontWeight.w500),
                                        ),
                                      ],
                                    )
                                    // Step tracking disabled view
                                        : Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        const Icon(
                                            Icons
                                                .directions_walk_rounded,
                                            color: AppColors
                                                .textSecondary,
                                            size: 36),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Step tracking is disabled',
                                          style: TextStyle(
                                              fontWeight:
                                              FontWeight.w600,
                                              color: AppColors
                                                  .textPrimary,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Enable it in Settings → Activity Tracking',
                                          style: TextStyle(
                                              color: AppColors
                                                  .textSecondary,
                                              fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Calories
                                  _sectionTitle('Calories'),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius:
                                        BorderRadius.circular(20)),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                              child: _calorieBlock(
                                                icon: Icons.restaurant_rounded,
                                                label: 'Calories Gained',
                                                value: mask('$totalGained'),
                                                unit: 'kcal',
                                                color: const Color(0xFF6FBF9F),
                                                bg: const Color(0xFFE8F5E9),
                                              )),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: _calorieBlock(
                                                icon: Icons
                                                    .local_fire_department_rounded,
                                                label: 'Calories Burned',
                                                value: mask('$totalBurned'),
                                                unit: 'kcal',
                                                color: const Color(0xFFE07A5F),
                                                bg: const Color(0xFFFFEBEE),
                                              )),
                                        ]),
                                        const SizedBox(height: 16),
                                        const Divider(
                                            height: 1,
                                            color: Color(0xFFF0F0F0)),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(children: [
                                              Icon(
                                                netCalories > 0
                                                    ? Icons
                                                    .trending_up_rounded
                                                    : Icons
                                                    .trending_down_rounded,
                                                size: 16,
                                                color: netCalories > 0
                                                    ? const Color(0xFFE07A5F)
                                                    : AppColors.greenDark,
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                  'Net (Gained − Burned)',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontWeight:
                                                      FontWeight.w500)),
                                            ]),
                                            Text(
                                              isPrivate
                                                  ? '•••• kcal'
                                                  : '${netCalories > 0 ? '+' : ''}$netCalories kcal',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: netCalories > 0
                                                      ? const Color(
                                                      0xFFE07A5F)
                                                      : AppColors.greenDark),
                                            ),
                                          ],
                                        ),
                                        if (!isPrivate) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            netCalories > 0
                                                ? 'You\'re in a calorie surplus. Consider more activity!'
                                                : 'Great! You\'re in a calorie deficit. Keep it up!',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: netCalories > 0
                                                    ? const Color(0xFFE07A5F)
                                                    : AppColors.greenDark),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Hydration
                                  _sectionTitle('Hydration'),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius:
                                        BorderRadius.circular(20)),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Container(
                                            padding:
                                            const EdgeInsets.all(10),
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
                                              Text(
                                                  mask(_waterDisplay(water)),
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                      color: AppColors
                                                          .textPrimary)),
                                              Text(
                                                  'of ${_waterDisplay(safeWaterGoal)} daily goal',
                                                  style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            isPrivate
                                                ? '••%'
                                                : '${((water / safeWaterGoal) * 100).clamp(0, 100).toInt()}%',
                                            style: const TextStyle(
                                                color: AppColors.blue,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16),
                                          ),
                                        ]),
                                        const SizedBox(height: 14),
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: isPrivate
                                                ? 0
                                                : (water / safeWaterGoal)
                                                .clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor:
                                            AppColors.inputField,
                                            valueColor:
                                            const AlwaysStoppedAnimation(
                                                Color(0xFF5C7C8A)),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(children: [
                                          Expanded(
                                            child: _WaterButton(
                                              imagePath:
                                              'assets/images/GLASS.png',
                                              label:
                                              '+200 ${vigorSettings.waterUnit}',
                                              onTap: () async {
                                                await userProfileRef.set(
                                                  {
                                                    'water': FieldValue
                                                        .increment(200)
                                                  },
                                                  SetOptions(merge: true),
                                                );
                                                // Only fire notification if water reminder is ON
                                                if (vigorSettings
                                                    .waterReminder) {
                                                  await showWaterNotification(
                                                      200);
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _WaterButton(
                                              imagePath:
                                              'assets/images/JUG.png',
                                              label:
                                              '+500 ${vigorSettings.waterUnit}',
                                              onTap: () async {
                                                await userProfileRef.set(
                                                  {
                                                    'water': FieldValue
                                                        .increment(500)
                                                  },
                                                  SetOptions(merge: true),
                                                );
                                                // Only fire notification if water reminder is ON
                                                if (vigorSettings
                                                    .waterReminder) {
                                                  await showWaterNotification(
                                                      500);
                                                }
                                              },
                                              isPrimary: true,
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  _actionTile(
                                    icon: Icons.logout_rounded,
                                    label: 'Logout',
                                    sublabel: 'Sign out of your account',
                                    iconColor: const Color(0xFFE07A5F),
                                    textColor: const Color(0xFFE07A5F),
                                    onTap: () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                              const auth_login
                                                  .LoginPage()),
                                              (route) => false);
                                    },
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

  // ── Helper widgets ──────────────────────────────────────────

  Widget _metricChip(IconData icon, String value, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: color)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
            ]),
          ]),
        ),
      );

  Widget _headerTag(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 12),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _headerIconBtn(
      {required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      );

  Widget _iconBox(
      {required IconData icon,
        required Color color,
        required Color bg}) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      );

  Widget _progressBar({required double value, required Color color}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 6,
          backgroundColor: AppColors.inputField,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3));

  Widget _calorieBlock({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required Color bg,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration:
        BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 10,
                            color: color.withOpacity(0.8),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: value,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: color)),
                          TextSpan(
                              text: ' $unit',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: color.withOpacity(0.7),
                                  fontWeight: FontWeight.w500)),
                        ])),
                  ])),
        ]),
      );

  Widget _statTile(
      String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 10),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ]),
        ),
      );

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String sublabel = '',
    Color iconColor = AppColors.blue,
    Color textColor = AppColors.textPrimary,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontSize: 14)),
                      if (sublabel.isNotEmpty)
                        Text(sublabel,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                    ])),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar with completion ring
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarWithRing extends StatelessWidget {
  final String initials;
  final bool isFemale;
  final String avatarBase64;
  final AvatarPreset resolvedPreset;
  final double completionRatio;
  final int percent;
  final bool isComplete;

  const _AvatarWithRing({
    required this.initials,
    required this.isFemale,
    required this.avatarBase64,
    required this.resolvedPreset,
    required this.completionRatio,
    required this.percent,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? photoProvider;
    if (avatarBase64.isNotEmpty) {
      try {
        photoProvider = MemoryImage(base64Decode(avatarBase64));
      } catch (_) {}
    }

    return Stack(alignment: Alignment.center, children: [
      SizedBox(
        width: 88,
        height: 88,
        child: isComplete
            ? const SizedBox.shrink()
            : CustomPaint(
          painter: _RingPainter(
              progress: completionRatio,
              activeColor: const Color(0xFF8FC9A9),
              trackColor: Colors.white.withOpacity(0.25)),
        ),
      ),
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: photoProvider != null ? null : resolvedPreset.bgColor,
          image: photoProvider != null
              ? DecorationImage(image: photoProvider, fit: BoxFit.cover)
              : null,
          border: isComplete
              ? Border.all(
              color: Colors.white.withOpacity(0.7), width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: photoProvider == null
            ? Center(
            child: Icon(resolvedPreset.icon,
                color: resolvedPreset.shirtColor, size: 30))
            : null,
      ),
      if (!isComplete)
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 4)
                ]),
            child: Text('$percent%',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ),
      Positioned(
        bottom: isComplete ? 4 : 22,
        right: 2,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.18), blurRadius: 5)
              ]),
          child: const Icon(Icons.camera_alt_rounded,
              size: 13, color: AppColors.blue),
        ),
      ),
      if (isComplete)
        Positioned(
          bottom: 4,
          left: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
                color: AppColors.greenDark,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2), blurRadius: 4)
                ]),
            child: const Icon(Icons.check_rounded,
                size: 13, color: Colors.white),
          ),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring painter
// ─────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  const _RingPainter(
      {required this.progress,
        required this.activeColor,
        required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 4.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - sw / 2;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159265 / 2,
        2 * 3.14159265 * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pedometer status chip
// ─────────────────────────────────────────────────────────────────────────────
class _PedometerChip extends StatelessWidget {
  final String status;
  final int liveSteps;
  const _PedometerChip({required this.status, required this.liveSteps});

  @override
  Widget build(BuildContext context) {
    final bool walking = status == 'walking';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: walking
            ? AppColors.greenDark.withOpacity(0.25)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          walking
              ? Icons.directions_walk_rounded
              : Icons.airline_seat_recline_normal_rounded,
          color: walking ? AppColors.greenLight : Colors.white70,
          size: 13,
        ),
        const SizedBox(width: 5),
        Text(
          walking ? 'Walking · $liveSteps steps' : 'Standing still',
          style: TextStyle(
              color: walking ? AppColors.greenLight : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Water Button
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Page
// ─────────────────────────────────────────────────────────────────────────────
class EditProfilePage extends StatefulWidget {
  final String username;
  const EditProfilePage({super.key, required this.username});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileRef =
  FirebaseFirestore.instance.collection('user_profiles');
  final _usersRef = FirebaseFirestore.instance.collection('users');

  final _basicFields = ['name', 'age', 'gender', 'city'];
  final _bodyFields = ['weight', 'height'];
  final _fitnessFields = [
    'fitnessLevel',
    'preferredActivity',
    'weeklyGoalDays',
    'goal',
    'bio'
  ];

  final fieldLabels = {
    'name': 'Full Name',
    'age': 'Age',
    'gender': 'Gender',
    'city': 'City',
    'weight': 'Weight',
    'height': 'Height',
    'fitnessLevel': 'Fitness Level',
    'preferredActivity': 'Preferred Activity',
    'weeklyGoalDays': 'Active Days per Week',
    'goal': 'Fitness Goal',
    'bio': 'About Me',
  };

  final fieldIcons = {
    'name': Icons.person_rounded,
    'age': Icons.cake_rounded,
    'gender': Icons.wc_rounded,
    'city': Icons.location_on_rounded,
    'weight': Icons.monitor_weight_rounded,
    'height': Icons.height_rounded,
    'fitnessLevel': Icons.bar_chart_rounded,
    'preferredActivity': Icons.sports_score_rounded,
    'weeklyGoalDays': Icons.calendar_month_rounded,
    'goal': Icons.flag_rounded,
    'bio': Icons.edit_note_rounded,
  };

  final _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final _fitnessOptions = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Athlete'
  ];
  final _activityOptions = [
    'Running',
    'Cycling',
    'Swimming',
    'Weightlifting',
    'Yoga',
    'HIIT',
    'Football',
    'Basketball',
    'Hiking',
    'Boxing',
  ];
  final _weeklyDayOptions = ['1', '2', '3', '4', '5', '6', '7'];

  Map<String, TextEditingController> controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (var f in [..._basicFields, ..._bodyFields, ..._fitnessFields]) {
      controllers[f] = TextEditingController();
    }
    _loadData();
  }

  @override
  void dispose() {
    controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  void _loadData() async {
    final pDoc = await _profileRef.doc(widget.username).get();
    final uDoc = await _usersRef.doc(widget.username).get();
    final merged = {
      if (uDoc.exists) ...uDoc.data()!,
      if (pDoc.exists) ...pDoc.data()!,
    };
    for (var f in controllers.keys) {
      controllers[f]!.text = merged[f]?.toString() ?? '';
    }
    setState(() {});
  }

  void _saveData() async {
    setState(() => _saving = true);
    final Map<String, dynamic> data = {};
    controllers.forEach((k, v) => data[k] = v.text);
    await _profileRef
        .doc(widget.username)
        .set(data, SetOptions(merge: true));
    await _usersRef
        .doc(widget.username)
        .set(data, SetOptions(merge: true));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  String _unitHint(String f) {
    if (f == 'weight') return 'Weight (${vigorSettings.weightUnit})';
    if (f == 'height') return 'Height (${vigorSettings.heightUnit})';
    return fieldLabels[f] ?? f;
  }

  TextInputType _keyboard(String f) {
    if (['age', 'weight', 'height', 'weeklyGoalDays'].contains(f))
      return TextInputType.number;
    if (f == 'bio') return TextInputType.multiline;
    return TextInputType.text;
  }

  List<String>? _dropdownOptions(String f) {
    switch (f) {
      case 'gender':
        return _genderOptions;
      case 'fitnessLevel':
        return _fitnessOptions;
      case 'preferredActivity':
        return _activityOptions;
      case 'weeklyGoalDays':
        return _weeklyDayOptions;
      default:
        return null;
    }
  }

  InputDecoration _inputDeco(String f) => InputDecoration(
    labelText: _unitHint(f),
    prefixIcon: Icon(fieldIcons[f] ?? Icons.edit_rounded,
        size: 18, color: AppColors.textSecondary),
    labelStyle:
    const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.blue, width: 1.5)),
    contentPadding:
    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  );

  Widget _buildField(String f) {
    final opts = _dropdownOptions(f);
    if (opts != null) {
      final cur = controllers[f]!.text;
      final valid = opts.contains(cur) ? cur : null;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          value: valid,
          isExpanded: true,
          decoration: _inputDeco(f),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary, size: 20),
          items: opts
              .map((o) => DropdownMenuItem(
              value: o,
              child: Text(o,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14))))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => controllers[f]!.text = v);
          },
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controllers[f],
        keyboardType: _keyboard(f),
        maxLines: f == 'bio' ? 3 : 1,
        style:
        const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: _inputDeco(f),
      ),
    );
  }

  Widget _groupCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> fields,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(9)),
                      child: Icon(icon, size: 15, color: color)),
                  const SizedBox(width: 9),
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.2)),
                ]),
              ),
              ...fields.map(_buildField),
            ]),
      );

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _saveData,
              child: _saving
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.blue))
                  : const Text('Save',
                  style: TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _groupCard(
              title: 'Basic Info',
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF5C7C8A),
              fields: _basicFields),
          _groupCard(
              title: 'Body Metrics',
              icon: Icons.straighten_rounded,
              color: const Color(0xFF6FBF9F),
              fields: _bodyFields),
          _groupCard(
              title: 'Fitness Profile',
              icon: Icons.fitness_center_rounded,
              color: const Color(0xFFE07A5F),
              fields: _fitnessFields),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveData,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: _saving
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes',
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
