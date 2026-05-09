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

// ── Synced Avatar List (Matches RegisterPage) ───────────────────────────────
final List<String> _kAvatars = [
  'https://cdn-icons-png.flaticon.com/128/4775/4775505.png',
  'https://cdn-icons-png.flaticon.com/128/14237/14237280.png',
  'https://cdn-icons-png.flaticon.com/128/3940/3940417.png',
  'https://cdn-icons-png.flaticon.com/128/1326/1326405.png',
  'https://cdn-icons-png.flaticon.com/128/1326/1326390.png',
  'https://cdn-icons-png.flaticon.com/128/4793/4793339.png',
  'https://cdn-icons-png.flaticon.com/128/4793/4793069.png',
  'https://cdn-icons-png.flaticon.com/128/4793/4793084.png',
  'https://cdn-icons-png.flaticon.com/128/4793/4793111.png',
  'https://cdn-icons-png.flaticon.com/128/4793/4793166.png',
  'https://cdn-icons-png.flaticon.com/128/4439/4439947.png',
  'https://cdn-icons-png.flaticon.com/128/11107/11107554.png',
  'https://cdn-icons-png.flaticon.com/128/1320/1320909.png',
  'https://cdn-icons-png.flaticon.com/128/1921/1921048.png',
  'https://cdn-icons-png.flaticon.com/128/2647/2647719.png',
  'https://cdn-icons-png.flaticon.com/128/4646/4646249.png'
];

// ─────────────────────────────────────────────────────────────────────────────
// App-level settings notifier
// ─────────────────────────────────────────────────────────────────────────────
class VigorSettings extends ChangeNotifier {
  bool _darkMode   = false;
  bool _privacyMode = false;

  bool get darkMode    => _darkMode;
  bool get privacyMode => _privacyMode;

  VigorSettings() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _darkMode    = p.getBool('darkMode')    ?? false;
    _privacyMode = p.getBool('privacyMode') ?? false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('darkMode', v);
  }

  Future<void> setPrivacyMode(bool v) async {
    _privacyMode = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('privacyMode', v);
  }
}

final vigorSettings = VigorSettings();

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
  bool _notifications = true;
  bool _waterReminder = true;
  bool _stepTracking  = true;
  bool _calorieAlerts = false;
  bool _weeklyReport  = true;
  String _units = 'Metric';

  final _waterGoalCtrl = TextEditingController();
  final _stepGoalCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    vigorSettings.addListener(_onSettingsChange);
  }

  void _onSettingsChange() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    vigorSettings.removeListener(_onSettingsChange);
    _waterGoalCtrl.dispose();
    _stepGoalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _waterReminder = prefs.getBool('waterReminder') ?? true;
      _stepTracking  = prefs.getBool('stepTracking')  ?? true;
      _calorieAlerts = prefs.getBool('calorieAlerts') ?? false;
      _weeklyReport  = prefs.getBool('weeklyReport')  ?? true;
      _units         = prefs.getString('units')       ?? 'Metric';
      _waterGoalCtrl.text = prefs.getString('waterGoal') ?? '2000';
      _stepGoalCtrl.text  = prefs.getString('stepGoal')  ?? '6000';
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)   prefs.setBool(key, value);
    if (value is String) prefs.setString(key, value);
  }

  Future<void> _saveGoalsToFirestore() async {
    final ref = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(widget.username);
    await ref.set({
      'stepGoal':  int.tryParse(_stepGoalCtrl.text)  ?? 6000,
      'waterGoal': int.tryParse(_waterGoalCtrl.text) ?? 2000,
    }, SetOptions(merge: true));
    await _savePref('stepGoal',  _stepGoalCtrl.text);
    await _savePref('waterGoal', _waterGoalCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals saved!'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _clearActivityData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Activity Data'),
        content: const Text(
            "This will reset today's water intake. Are you sure?"),
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
          const SnackBar(content: Text('Activity data cleared.'),
              duration: Duration(seconds: 2)),
        );
      }
    }
  }

  Color get _bg    => vigorSettings.darkMode ? const Color(0xFF1A1A2E) : AppColors.background;
  Color get _card  => vigorSettings.darkMode ? const Color(0xFF252540) : AppColors.white;
  Color get _text  => vigorSettings.darkMode ? Colors.white : AppColors.textPrimary;
  Color get _sub   => vigorSettings.darkMode ? Colors.white54 : AppColors.textSecondary;

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
    child: Text(t,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: _sub, letterSpacing: 0.8)),
  );

  Widget _settingsTile({
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
          decoration: BoxDecoration(color: _card,
              borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Text(label,
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: _text)),
            subtitle: Text(sublabel,
                style: TextStyle(fontSize: 11, color: _sub)),
            trailing: trailing,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = vigorSettings.darkMode;
    final isPrivate = vigorSettings.privacyMode;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Settings',
            style: TextStyle(color: _text,
                fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: IconThemeData(color: _text),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [

          _sectionTitle('APPEARANCE'),
          _settingsTile(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            label: isDark ? 'Light Mode' : 'Dark Mode',
            sublabel: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            color: const Color(0xFF5C7C8A),
            trailing: Switch.adaptive(
              value: isDark,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setDarkMode(v),
            ),
          ),
          _settingsTile(
            icon: Icons.straighten_rounded,
            label: 'Units',
            sublabel: _units == 'Metric' ? 'kg, cm, ml' : 'lbs, ft, fl oz',
            color: const Color(0xFF6FBF9F),
            trailing: GestureDetector(
              onTap: () {
                final next = _units == 'Metric' ? 'Imperial' : 'Metric';
                setState(() => _units = next);
                _savePref('units', next);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FBF9F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_units,
                    style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6FBF9F))),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _sectionTitle('NOTIFICATIONS'),
          _settingsTile(
            icon: Icons.notifications_rounded,
            label: 'Push Notifications',
            sublabel: 'Workout reminders & updates',
            color: const Color(0xFFE07A5F),
            trailing: Switch.adaptive(
              value: _notifications,
              activeColor: AppColors.greenDark,
              onChanged: (v) {
                setState(() => _notifications = v);
                _savePref('notifications', v);
              },
            ),
          ),
          _settingsTile(
            icon: Icons.water_drop_rounded,
            label: 'Water Reminders',
            sublabel: 'Get reminded to stay hydrated',
            color: const Color(0xFF5C7C8A),
            trailing: Switch.adaptive(
              value: _waterReminder,
              activeColor: AppColors.greenDark,
              onChanged: (v) {
                setState(() => _waterReminder = v);
                _savePref('waterReminder', v);
              },
            ),
          ),
          _settingsTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Calorie Alerts',
            sublabel: 'Alert when daily target is exceeded',
            color: const Color(0xFFE07A5F),
            trailing: Switch.adaptive(
              value: _calorieAlerts,
              activeColor: AppColors.greenDark,
              onChanged: (v) {
                setState(() => _calorieAlerts = v);
                _savePref('calorieAlerts', v);
              },
            ),
          ),
          _settingsTile(
            icon: Icons.bar_chart_rounded,
            label: 'Weekly Report',
            sublabel: 'Summary of your weekly activity',
            color: const Color(0xFF6FBF9F),
            trailing: Switch.adaptive(
              value: _weeklyReport,
              activeColor: AppColors.greenDark,
              onChanged: (v) {
                setState(() => _weeklyReport = v);
                _savePref('weeklyReport', v);
              },
            ),
          ),

          const SizedBox(height: 12),

          _sectionTitle('ACTIVITY TRACKING'),
          _settingsTile(
            icon: Icons.directions_walk_rounded,
            label: 'Step Tracking',
            sublabel: 'Count steps using pedometer',
            color: const Color(0xFF6FBF9F),
            trailing: Switch.adaptive(
              value: _stepTracking,
              activeColor: AppColors.greenDark,
              onChanged: (v) {
                setState(() => _stepTracking = v);
                _savePref('stepTracking', v);
              },
            ),
          ),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _card,
                borderRadius: BorderRadius.circular(14)),
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
                      style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w700, color: _text)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextField(
                    controller: _stepGoalCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: _text, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Step Goal',
                      prefixIcon: const Icon(Icons.directions_walk_rounded,
                          size: 16, color: AppColors.textSecondary),
                      labelStyle: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A2E)
                          : AppColors.background,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: _waterGoalCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: _text, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Water Goal (ml)',
                      prefixIcon: const Icon(Icons.water_drop_rounded,
                          size: 16, color: AppColors.textSecondary),
                      labelStyle: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1A1A2E)
                          : AppColors.background,
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
                        style: TextStyle(color: AppColors.white,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _sectionTitle('PRIVACY & SECURITY'),
          _settingsTile(
            icon: Icons.lock_rounded,
            label: 'Privacy Mode',
            sublabel: isPrivate
                ? 'Stats hidden — tap to reveal'
                : 'Stats visible to you',
            color: const Color(0xFF9B8EA8),
            trailing: Switch.adaptive(
              value: isPrivate,
              activeColor: AppColors.greenDark,
              onChanged: (v) => vigorSettings.setPrivacyMode(v),
            ),
          ),
          _settingsTile(
            icon: Icons.delete_outline_rounded,
            label: 'Clear Activity Data',
            sublabel: "Reset today's water intake",
            color: const Color(0xFFE07A5F),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
            onTap: _clearActivityData,
          ),

          const SizedBox(height: 12),

          _sectionTitle('ABOUT'),
          _settingsTile(
            icon: Icons.info_outline_rounded,
            label: 'App Version',
            sublabel: 'Vigor v1.0.0',
            color: const Color(0xFF5C7C8A),
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfilePage
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
    _initPedometer();
  }

  Future<void> _initPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return;
    _stepSub = Pedometer.stepCountStream.listen(
          (e) {
        if (!mounted) return;
        setState(() {
          if (_stepBaseline == -1) _stepBaseline = e.steps;
          _liveSteps = (e.steps - _stepBaseline).clamp(0, 999999);
        });
      },
      onError: (e) => debugPrint('Step error: $e'),
    );
    _statusSub = Pedometer.pedestrianStatusStream.listen(
          (e) {
        if (mounted) setState(() => _pedestrianStatus = e.status);
      },
      onError: (e) => debugPrint('Status error: $e'),
    );
  }

  @override
  void dispose() {
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

  Future<void> _pickImage(ImageSource source, DocumentReference userRef, DocumentReference profileRef) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile == null) return;

    final bytes = await File(pickedFile.path).readAsBytes();
    final base64String = base64Encode(bytes);

    // Sync to both locations
    await userRef.set({'avatarBase64': base64String, 'avatar': ''}, SetOptions(merge: true));
    await profileRef.set({'avatarBase64': base64String, 'avatar': ''}, SetOptions(merge: true));
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showAvatarOptions(BuildContext context, DocumentReference userRef, DocumentReference profileRef, String currentAvatar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const Text('Choose Your Avatar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 100, crossAxisSpacing: 15, mainAxisSpacing: 15),
              itemCount: _kAvatars.length,
              itemBuilder: (_, i) {
                final url = _kAvatars[i];
                bool isSelected = currentAvatar == url;
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    // Update both collections and clear base64
                    await userRef.set({'avatar': url, 'avatarBase64': ''}, SetOptions(merge: true));
                    await profileRef.set({'avatar': url, 'avatarBase64': ''}, SetOptions(merge: true));
                  },
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppColors.green : Colors.transparent, width: 3)),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 1)),
                      child: CircleAvatar(backgroundImage: NetworkImage(url), backgroundColor: AppColors.card),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _photoOption(icon: Icons.camera_alt_rounded, label: 'Take a Photo', color: AppColors.green, onTap: () async => await _pickImage(ImageSource.camera, userRef, profileRef)),
          const SizedBox(height: 10),
          _photoOption(icon: Icons.photo_library_rounded, label: 'Pick from Gallery', color: AppColors.blue, onTap: () async => await _pickImage(ImageSource.gallery, userRef, profileRef)),
        ]),
      ),
    );
  }

  Widget _photoOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
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
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4), size: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileRef = FirebaseFirestore.instance.collection('user_profiles').doc(widget.username);
    final usersRef = FirebaseFirestore.instance.collection('users').doc(widget.username);

    final profileFields = ['name', 'age', 'gender', 'weight', 'height', 'goal', 'city', 'fitnessLevel', 'preferredActivity', 'weeklyGoalDays', 'bio'];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, authSnap) {
          final authData = (authSnap.data?.data() as Map<String, dynamic>?) ?? {};
          return StreamBuilder<DocumentSnapshot>(
            stream: userProfileRef.snapshots(),
            builder: (context, profileSnap) {
              if (!profileSnap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.green));
              final profileData = (profileSnap.data?.data() as Map<String, dynamic>?) ?? {};
              final merged = {...profileData, ...authData};

              final String displayName = merged['name']?.toString() ?? widget.username;
              final String displayCity = merged['city']?.toString() ?? 'No city set';
              final String displayGoal = merged['goal']?.toString() ?? '';
              final String displayBio = merged['bio']?.toString() ?? '';
              final String displayFitnessLevel = merged['fitnessLevel']?.toString() ?? '';
              final String displayActivity = merged['preferredActivity']?.toString() ?? '';

              final String avatarUrl = merged['avatar']?.toString() ?? '';
              final String avatarBase64 = merged['avatarBase64']?.toString() ?? '';

              int filled = profileFields.where((f) => merged[f] != null && merged[f].toString().isNotEmpty).length;
              double completionRatio = filled / profileFields.length;
              int percent = (completionRatio * 100).toInt();
              bool isComplete = percent >= 100;

              final String initials = displayName.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

              int safeGoal = _parse(profileData['stepGoal']);
              if (safeGoal == 0) safeGoal = 6000;
              int water = _parse(profileData['water']);
              int waterGoal = _parse(profileData['waterGoal']);
              if (waterGoal == 0) waterGoal = 2000;

              double distanceKm = _liveSteps * 0.000762;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('workout_history').where('username', isEqualTo: widget.username).snapshots(),
                builder: (context, workoutSnap) {
                  int totalWorkouts = 0; int totalBurned = 0; int streak = 0;
                  if (workoutSnap.hasData) {
                    final dates = <DateTime>{};
                    for (var d in workoutSnap.data!.docs) {
                      final m = d.data() as Map<String, dynamic>;
                      totalWorkouts++;
                      totalBurned += _parse(m['calories'] ?? m['burned'] ?? m['caloriesBurned']);
                      final ts = m['timestamp'];
                      if (ts is Timestamp) {
                        final dt = ts.toDate();
                        dates.add(DateTime(dt.year, dt.month, dt.day));
                      }
                    }
                    final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
                    DateTime check = DateTime.now();
                    check = DateTime(check.year, check.month, check.day);
                    for (final d in sorted) {
                      if (d == check || d == check.subtract(const Duration(days: 1))) {
                        streak++; check = d == check ? check.subtract(const Duration(days: 1)) : d.subtract(const Duration(days: 1));
                      } else break;
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('meals').where('userId', isEqualTo: widget.username).snapshots(),
                    builder: (context, mealSnap) {
                      int totalGained = 0;
                      if (mealSnap.hasData) {
                        for (var d in mealSnap.data!.docs) {
                          final m = d.data() as Map<String, dynamic>;
                          totalGained += _parse(m['calories'] ?? m['gained']);
                        }
                      }
                      int netCalories = totalGained - totalBurned;

                      return CustomScrollView(slivers: [
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                                colors: [Color(0xFF3A6B82), Color(0xFF2A5068), Color(0xFF1E3D52)],
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                GestureDetector(
                                  onTap: () => _showAvatarOptions(context, usersRef, userProfileRef, avatarUrl),
                                  child: _AvatarWithRing(initials: initials, avatarUrl: avatarUrl, avatarBase64: avatarBase64, completionRatio: completionRatio, percent: percent, isComplete: isComplete),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                  if (displayBio.isNotEmpty) Text(displayBio, style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.location_on_rounded, color: Colors.white54, size: 12),
                                    const SizedBox(width: 3),
                                    Flexible(child: Text(displayCity, style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  ]),
                                  const SizedBox(height: 8),
                                  _PedometerChip(status: _pedestrianStatus, liveSteps: _liveSteps),
                                ])),
                                _headerIconBtn(icon: Icons.notifications_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityPage(username: widget.username)))),
                              ]),
                              const SizedBox(height: 14),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Wrap(spacing: 8, children: [
                                  if (displayFitnessLevel.isNotEmpty) _headerTag(Icons.bar_chart_rounded, displayFitnessLevel),
                                  if (displayGoal.isNotEmpty) _headerTag(Icons.flag_rounded, displayGoal),
                                ]),
                                Row(children: [
                                  _headerIconBtn(icon: Icons.edit_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(username: widget.username)))),
                                  const SizedBox(width: 8),
                                  _headerIconBtn(icon: Icons.settings_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(username: widget.username)))),
                                ]),
                              ]),
                            ]),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              _statTile('Workouts', '$totalWorkouts', Icons.fitness_center_rounded, const Color(0xFF5C7C8A)),
                              const SizedBox(width: 10),
                              _statTile('Streak', '$streak days', Icons.local_fire_department_rounded, const Color(0xFFE07A5F)),
                            ]),
                            const SizedBox(height: 24),
                            _sectionTitle("Today's Steps"),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                              child: Column(children: [
                                Row(children: [
                                  _iconBox(icon: Icons.directions_walk_rounded, color: const Color(0xFF5C7C8A), bg: const Color(0xFFDCEEF5)),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('$_liveSteps steps', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    Text('Goal: $safeGoal · ${distanceKm.toStringAsFixed(2)} km', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ])),
                                  Text('${((_liveSteps / safeGoal) * 100).toInt()}%', style: const TextStyle(color: Color(0xFF5C7C8A), fontWeight: FontWeight.w700, fontSize: 16)),
                                ]),
                                const SizedBox(height: 14),
                                _progressBar(value: (_liveSteps / safeGoal).clamp(0.0, 1.0), color: const Color(0xFF5C7C8A)),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _sectionTitle('Calories'),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                              child: Column(children: [
                                Row(children: [
                                  Expanded(child: _calorieBlock(icon: Icons.restaurant_rounded, label: 'Gained', value: '$totalGained', unit: 'kcal', color: const Color(0xFF6FBF9F), bg: const Color(0xFFE8F5E9))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _calorieBlock(icon: Icons.local_fire_department_rounded, label: 'Burned', value: '$totalBurned', unit: 'kcal', color: const Color(0xFFE07A5F), bg: const Color(0xFFFFEBEE))),
                                ]),
                                const SizedBox(height: 16),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('Net Calories', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  Text('${netCalories > 0 ? '+' : ''}$netCalories kcal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: netCalories > 0 ? const Color(0xFFE07A5F) : AppColors.greenDark)),
                                ]),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _sectionTitle('Hydration'),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                              child: Column(children: [
                                Row(children: [
                                  _iconBox(icon: Icons.water_drop_rounded, color: const Color(0xFF5C7C8A), bg: const Color(0xFFDCEEF5)),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('$water ml', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    Text('Goal: $waterGoal ml', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ])),
                                  Text('${((water / waterGoal) * 100).toInt()}%', style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 16)),
                                ]),
                                const SizedBox(height: 14),
                                _progressBar(value: (water / waterGoal).clamp(0.0, 1.0), color: const Color(0xFF5C7C8A)),
                                const SizedBox(height: 16),
                                Row(children: [
                                  Expanded(child: _WaterButton(imagePath: 'assets/images/GLASS.png', label: '+200 ml', onTap: () async {
                                    await userProfileRef.set({'water': FieldValue.increment(200)}, SetOptions(merge: true));
                                    await showWaterNotification(200);
                                  })),
                                  const SizedBox(width: 12),
                                  Expanded(child: _WaterButton(imagePath: 'assets/images/JUG.png', label: '+500 ml', onTap: () async {
                                    await userProfileRef.set({'water': FieldValue.increment(500)}, SetOptions(merge: true));
                                    await showWaterNotification(500);
                                  }, isPrimary: true)),
                                ]),
                              ]),
                            ),
                            const SizedBox(height: 24),
                            _actionTile(icon: Icons.logout_rounded, label: 'Logout', sublabel: 'Sign out of your account', iconColor: const Color(0xFFE07A5F), onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const auth_login.LoginPage()), (r) => false);
                            }),
                            const SizedBox(height: 32),
                          ])),
                        ),
                      ]);
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

  Widget _headerTag(IconData icon, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white70, size: 12), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))]));
  Widget _headerIconBtn({required IconData icon, required VoidCallback onTap}) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.white, size: 20)));
  Widget _iconBox({required IconData icon, required Color color, required Color bg}) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20));
  Widget _progressBar({required double value, required Color color}) => ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: value, minHeight: 6, backgroundColor: AppColors.inputField, valueColor: AlwaysStoppedAnimation(color)));
  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3));
  Widget _calorieBlock({required IconData icon, required String label, required String value, required String unit, required Color color, required Color bg}) => Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)), const SizedBox(height: 2), RichText(text: TextSpan(children: [TextSpan(text: value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)), TextSpan(text: ' $unit', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7), fontWeight: FontWeight.w500))]))]))]));
  Widget _statTile(String label, String value, IconData icon, Color color) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 16)), const SizedBox(height: 10), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textPrimary)), const SizedBox(height: 2), Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10))])));
  Widget _actionTile({required IconData icon, required String label, required String sublabel, required Color iconColor, required VoidCallback onTap}) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 18)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), Text(sublabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))])), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20)])));
}

class _AvatarWithRing extends StatelessWidget {
  final String initials;
  final String avatarUrl;
  final String avatarBase64;
  final double completionRatio;
  final int percent;
  final bool isComplete;

  const _AvatarWithRing({required this.initials, required this.avatarUrl, required this.avatarBase64, required this.completionRatio, required this.percent, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    ImageProvider? photoProvider;
    if (avatarBase64.isNotEmpty) {
      try { photoProvider = MemoryImage(base64Decode(avatarBase64)); } catch (_) {}
    } else if (avatarUrl.isNotEmpty) {
      photoProvider = NetworkImage(avatarUrl);
    }

    return Stack(alignment: Alignment.center, children: [
      SizedBox(width: 88, height: 88, child: isComplete ? const SizedBox.shrink() : CustomPaint(painter: _RingPainter(progress: completionRatio, activeColor: const Color(0xFF8FC9A9), trackColor: Colors.white.withOpacity(0.25)))),
      Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: photoProvider != null ? DecorationImage(image: photoProvider, fit: BoxFit.cover) : null,
          color: photoProvider == null ? AppColors.blue : null,
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: photoProvider == null ? Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))) : null,
      ),
      if (!isComplete) Positioned(bottom: 0, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(8)), child: Text('$percent%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)))),
      Positioned(bottom: isComplete ? 4 : 22, right: 2, child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 13, color: AppColors.blue))),
      if (isComplete) Positioned(bottom: 4, left: 0, child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppColors.greenDark, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 13, color: Colors.white))),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;
  _RingPainter({required this.progress, required this.activeColor, required this.trackColor});
  @override
  void paint(Canvas canvas, Size size) {
    const sw = 4.0; final center = Offset(size.width / 2, size.height / 2); final radius = (size.width / 2) - sw / 2;
    canvas.drawCircle(center, radius, Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = sw);
    if (progress > 0) canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.570796, 6.283185 * progress.clamp(0.0, 1.0), false, Paint()..color = activeColor..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

class _PedometerChip extends StatelessWidget {
  final String status;
  final int liveSteps;
  const _PedometerChip({required this.status, required this.liveSteps});
  @override
  Widget build(BuildContext context) {
    final bool walking = status == 'walking';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: walking ? AppColors.greenDark.withOpacity(0.25) : Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(walking ? Icons.directions_walk_rounded : Icons.airline_seat_recline_normal_rounded, color: walking ? AppColors.greenLight : Colors.white70, size: 13), const SizedBox(width: 5), Text(walking ? 'Walking · $liveSteps steps' : 'Standing still', style: TextStyle(color: walking ? AppColors.greenLight : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))]));
  }
}

class _WaterButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const _WaterButton({required this.imagePath, required this.label, required this.onTap, this.isPrimary = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isPrimary ? AppColors.greenDark : AppColors.inputField, borderRadius: BorderRadius.circular(14)), child: Column(mainAxisSize: MainAxisSize.min, children: [Image.asset(imagePath, height: 32), const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPrimary ? AppColors.white : AppColors.textPrimary))])));
  }
}

class EditProfilePage extends StatefulWidget {
  final String username;
  const EditProfilePage({super.key, required this.username});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _profileRef = FirebaseFirestore.instance.collection('user_profiles');
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _basicFields = ['name', 'age', 'gender', 'city'];
  final _bodyFields = ['weight', 'height'];
  final _fitnessFields = ['fitnessLevel', 'preferredActivity', 'weeklyGoalDays', 'goal', 'bio'];
  final fieldLabels = {'name': 'Full Name', 'age': 'Age', 'gender': 'Gender', 'city': 'City', 'weight': 'Weight (kg)', 'height': 'Height (cm)', 'fitnessLevel': 'Fitness Level', 'preferredActivity': 'Preferred Activity', 'weeklyGoalDays': 'Active Days/Week', 'goal': 'Fitness Goal', 'bio': 'About Me'};
  final fieldIcons = {'name': Icons.person_rounded, 'age': Icons.cake_rounded, 'gender': Icons.wc_rounded, 'city': Icons.location_on_rounded, 'weight': Icons.monitor_weight_rounded, 'height': Icons.height_rounded, 'fitnessLevel': Icons.bar_chart_rounded, 'preferredActivity': Icons.sports_score_rounded, 'weeklyGoalDays': Icons.calendar_month_rounded, 'goal': Icons.flag_rounded, 'bio': Icons.edit_note_rounded};
  final _genderOptions = ['Male', 'Female', 'Other'];
  final _fitnessOptions = ['Beginner', 'Intermediate', 'Advanced', 'Athlete'];
  final _activityOptions = ['Running', 'Cycling', 'Swimming', 'Weightlifting', 'Yoga', 'HIIT', 'Hiking', 'Boxing'];
  final _weeklyDayOptions = ['1', '2', '3', '4', '5', '6', '7'];

  Map<String, TextEditingController> controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (var f in [..._basicFields, ..._bodyFields, ..._fitnessFields]) controllers[f] = TextEditingController();
    _loadData();
  }

  void _loadData() async {
    final pDoc = await _profileRef.doc(widget.username).get();
    final uDoc = await _usersRef.doc(widget.username).get();
    final merged = {if (uDoc.exists) ...uDoc.data()!, if (pDoc.exists) ...pDoc.data()!};
    for (var f in controllers.keys) controllers[f]!.text = merged[f]?.toString() ?? '';
    setState(() {});
  }

  void _saveData() async {
    setState(() => _saving = true);
    final Map<String, dynamic> data = {};
    controllers.forEach((k, v) => data[k] = v.text);
    await _profileRef.doc(widget.username).set(data, SetOptions(merge: true));
    await _usersRef.doc(widget.username).set(data, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)), backgroundColor: AppColors.background, elevation: 0, iconTheme: const IconThemeData(color: AppColors.textPrimary), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _groupCard(title: 'Basic Info', icon: Icons.person_outline_rounded, color: const Color(0xFF5C7C8A), fields: _basicFields),
        _groupCard(title: 'Body Metrics', icon: Icons.straighten_rounded, color: const Color(0xFF6FBF9F), fields: _bodyFields),
        _groupCard(title: 'Fitness Profile', icon: Icons.fitness_center_rounded, color: const Color(0xFFE07A5F), fields: _fitnessFields),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _saving ? null : _saveData, child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'))),
      ]),
    );
  }

  Widget _groupCard({required String title, required IconData icon, required Color color, required List<String> fields}) => Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.12))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 15, color: color)), const SizedBox(width: 9), Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))])),
      ...fields.map((f) {
        final opts = f == 'gender' ? _genderOptions : (f == 'fitnessLevel' ? _fitnessOptions : (f == 'preferredActivity' ? _activityOptions : (f == 'weeklyGoalDays' ? _weeklyDayOptions : null)));
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: opts != null ? DropdownButtonFormField<String>(value: opts.contains(controllers[f]!.text) ? controllers[f]!.text : null, decoration: InputDecoration(labelText: fieldLabels[f], prefixIcon: Icon(fieldIcons[f], size: 18)), items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(), onChanged: (v) => setState(() => controllers[f]!.text = v!)) : TextField(controller: controllers[f], decoration: InputDecoration(labelText: fieldLabels[f], prefixIcon: Icon(fieldIcons[f], size: 18)), keyboardType: ['age', 'weight', 'height', 'weeklyGoalDays'].contains(f) ? TextInputType.number : TextInputType.text));
      }),
    ]),
  );
}
