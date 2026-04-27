import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vigor/Pages/Community.dart';
import 'package:vigor/Auth/login_page.dart'as service_login;

import 'package:vigor/Auth/login_page.dart' as auth_login;
import 'package:vigor/Pages/Workout/workout_home.dart';
import 'firebase_options.dart';


import 'Pages/Diet.dart';
import 'Pages/Profile.dart';
import 'Pages/Workout/seed_workouts.dart';
import 'utils/session.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await seedWorkouts();
  await Session.loadUser();
  if (Session.getUser() == null) {
    await Session.setUser("Shru_22");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Using Auth/login_page.dart as the starting point if not using StreamBuilder
      // For now, let's keep it simple as per your manual login/register flow
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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Diet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}