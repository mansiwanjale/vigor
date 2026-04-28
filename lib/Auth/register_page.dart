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
  final _nameController       = TextEditingController();
  final _emailController      = TextEditingController();
  final _usernameController   = TextEditingController();
  final _passwordController   = TextEditingController();
  final _ageController        = TextEditingController();
  final _cityController       = TextEditingController();
  final _heightController     = TextEditingController();
  final _weightController     = TextEditingController();

  String _selectedGender = 'female';
  String _selectedGoal   = 'Weight Loss';
  bool _isLoading        = false;
  bool _obscure          = true;
  int _step              = 0; // 0 = account info, 1 = body info

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> _registerUser() async {
    String uname = _usernameController.text.trim();
    String pass  = _passwordController.text.trim();

    if (uname.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      var userCheck = await FirebaseFirestore.instance
          .collection('users').doc(uname).get();
      if (userCheck.exists) throw "Username already taken.";

      await FirebaseFirestore.instance.collection('users').doc(uname).set({
        "name"            : _nameController.text.trim(),
        "email"           : _emailController.text.trim(),
        "username"        : uname,
        "password"        : _hashPassword(pass),
        "age"             : int.tryParse(_ageController.text) ?? 0,
        "gender"          : _selectedGender,
        "city"            : _cityController.text.trim(),
        "goal"            : _selectedGoal,
        "height"          : double.tryParse(_heightController.text) ?? 0.0,
        "weight"          : double.tryParse(_weightController.text) ?? 0.0,
        "isLoggedIn"      : true,
        "profileComplete" : true,
        "createdAt"       : FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => NavigationPage(username: uname)),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _step == 1
                        ? setState(() => _step = 0)
                        : Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Step indicator
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _step == 0 ? 0.5 : 1.0,
                        minHeight: 5,
                        backgroundColor: AppColors.card,
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${_step + 1} / 2',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _step == 0 ? 'Create your\naccount.' : 'About\nyour body.',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.15,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _step == 0
                        ? 'Let\'s get you started with Vigor'
                        : 'Helps us personalize your experience',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Form ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _step == 0 ? _stepOne() : _stepTwo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepOne() {
    return Column(
      children: [
        _field('Full Name', _nameController,
            icon: Icons.badge_outlined),
        _field('Username', _usernameController,
            icon: Icons.alternate_email_rounded),
        _field('Email', _emailController,
            icon: Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress),
        _field('Password', _passwordController,
            icon: Icons.lock_outline_rounded,
            obscure: true),
        const SizedBox(height: 28),
        _nextButton('Continue', () => setState(() => _step = 1)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _stepTwo() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _field('Age', _ageController,
              icon: Icons.cake_outlined,
              keyboard: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field('City', _cityController,
              icon: Icons.location_city_outlined)),
        ]),
        Row(children: [
          Expanded(child: _field('Height (cm)', _heightController,
              icon: Icons.height_rounded,
              keyboard: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field('Weight (kg)', _weightController,
              icon: Icons.monitor_weight_outlined,
              keyboard: TextInputType.number)),
        ]),
        _dropdown(
          label: 'Gender',
          value: _selectedGender,
          items: ['male', 'female', 'other'],
          onChanged: (v) => setState(() => _selectedGender = v!),
        ),
        const SizedBox(height: 16),
        _dropdown(
          label: 'Fitness Goal',
          value: _selectedGoal,
          items: ['Weight Loss', 'Muscle Gain', 'Endurance', 'Yoga'],
          onChanged: (v) => setState(() => _selectedGoal = v!),
        ),
        const SizedBox(height: 28),
        _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.green))
            : _nextButton('Create Account', _registerUser),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        required IconData icon,
        bool obscure = false,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure && _obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          filled: true,
          fillColor: AppColors.white,
          prefixIcon:
          Icon(icon, color: AppColors.textSecondary, size: 19),
          suffixIcon: obscure
              ? GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textSecondary,
              size: 19,
            ),
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          border: InputBorder.none,
        ),
        dropdownColor: AppColors.white,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        items: items
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _nextButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenDark,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}