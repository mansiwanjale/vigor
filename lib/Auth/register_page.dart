import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedGender = "female";
  String _selectedGoal = "Weight Loss";
  bool _isLoading = false;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _registerUser() async {
    String uname = _usernameController.text.trim();
    String pass = _passwordController.text.trim();

    if (uname.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      var userCheck = await FirebaseFirestore.instance.collection('users').doc(uname).get();
      if (userCheck.exists) {
        throw "Username already taken.";
      }

      String hashedPassword = _hashPassword(pass);

      await FirebaseFirestore.instance.collection('users').doc(uname).set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "username": uname,
        "password": hashedPassword,
        "age": int.tryParse(_ageController.text) ?? 0,
        "gender": _selectedGender,
        "city": _cityController.text.trim(),
        "goal": _selectedGoal,
        "height": double.tryParse(_heightController.text) ?? 0.0,
        "weight": double.tryParse(_weightController.text) ?? 0.0,
        "isLoggedIn": true,
        "profileComplete": true,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => NavigationPage(username: uname)),
            (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _ageController, decoration: const InputDecoration(labelText: "Age"), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _cityController, decoration: const InputDecoration(labelText: "City"))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: _heightController, decoration: const InputDecoration(labelText: "Height (cm)"), keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _weightController, decoration: const InputDecoration(labelText: "Weight (kg)"), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: _selectedGender,
              items: ["male", "female", "other"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGender = val as String),
              decoration: const InputDecoration(labelText: "Gender"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: _selectedGoal,
              items: ["Weight Loss", "Muscle Gain", "Endurance", "Yoga"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGoal = val as String),
              decoration: const InputDecoration(labelText: "Fitness Goal"),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(onPressed: _registerUser, child: const Text("Register & Start")),
                  ),
          ],
        ),
      ),
    );
  }
}