import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vigor/Pages/Community.dart';
import 'package:vigor/Auth/login_page.dart' as auth_login;
import 'package:vigor/Pages/Workout/workout_home.dart';
import 'firebase_options.dart';
import 'Pages/Diet.dart';
import 'Pages/Profile.dart';
import 'session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // 💡 Removed seedWorkouts() to prevent unnecessary database writes
  // You can now manage your workouts directly from the Firebase Console
  
  await Session.loadUser();
  runApp(const MyApp());
}

// ── Palette ────────────────────────────────────────────────
class AppColors {
  static const background   = Color(0xFFF5F1E9);
  static const card         = Color(0xFFE8E2D8);
  static const cardDark     = Color(0xFF1C1F22); 
  static const green        = Color(0xFF6FBF9F); 
  static const greenDark    = Color(0xFF4CAF8E);
  static const greenLight   = Color(0xFFA8D5BA);
  static const blue         = Color(0xFF5C7C8A);
  static const blueDark     = Color(0xFF2F4F6F);
  static const textPrimary  = Color(0xFF1C1F22);
  static const textSecondary= Color(0xFFA0A4A8);
  static const white        = Color(0xFFFFFFFF);
  static const inputField   = Color(0xFFF0F4F8);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.green,
          secondary: AppColors.blue,
          surface: AppColors.card,
          onPrimary: AppColors.white,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.blue,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.greenDark,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputField,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.green,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          elevation: 8,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
        ),
        useMaterial3: false,
      ),
      home: const auth_login.LoginPage(),
    );
  }
}

class NavigationPage extends StatefulWidget {
  final String username;
  const NavigationPage({super.key, required this.username});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const WorkoutHome(),
      const Community(),
      DietPage(),
      ProfilePage(username: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_rounded), label: 'Diet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
