import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Pages/main_menu_page.dart';
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

  String _selectedGender = 'female';
  String _selectedGoal = 'Weight Loss';

  String _selectedAvatar =
      'https://cdn-icons-png.flaticon.com/512/924/924915.png';

  bool _isLoading = false;
  bool _obscure = true;
  int _step = 0;

  final List<String> _avatars = [
    'https://cdn-icons-png.flaticon.com/128/4775/4775505.png',
    'https://cdn-icons-png.flaticon.com/128/14237/14237280.png',
    'https://cdn-icons-png.flaticon.com/128/3940/3940417.png',
    'https://cdn-icons-png.flaticon.com/128/1326/1326405.png',
    'https://cdn-icons-png.flaticon.com/128/1326/1326390.png',

    //Greek Gods
    'https://cdn-icons-png.flaticon.com/128/4793/4793339.png',
    'https://cdn-icons-png.flaticon.com/128/4793/4793069.png',
    'https://cdn-icons-png.flaticon.com/128/4793/4793084.png',
    'https://cdn-icons-png.flaticon.com/512/924/924915.png',
    'https://cdn-icons-png.flaticon.com/512/194/194938.png',
    'https://cdn-icons-png.flaticon.com/512/4333/4333609.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
    'https://cdn-icons-png.flaticon.com/512/1154/1154444.png',
    'https://cdn-icons-png.flaticon.com/512/6997/6997662.png',
    'https://cdn-icons-png.flaticon.com/128/4793/4793111.png',
    'https://cdn-icons-png.flaticon.com/128/4793/4793166.png',

    // Random Characters
    'https://cdn-icons-png.flaticon.com/128/4439/4439947.png',
    'https://cdn-icons-png.flaticon.com/128/11107/11107554.png',
    'https://cdn-icons-png.flaticon.com/128/1320/1320909.png',
    'https://cdn-icons-png.flaticon.com/128/1921/1921048.png',
    'https://cdn-icons-png.flaticon.com/128/2647/2647719.png',
    'https://cdn-icons-png.flaticon.com/128/4646/4646249.png'
  ];

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  bool _validateStep0() {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError("All fields are required");
      return false;
    }

    return true;
  }

  bool _validateStep1() {
    if (_ageController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _heightController.text.trim().isEmpty ||
        _weightController.text.trim().isEmpty) {
      _showError("All body metrics are required");
      return false;
    }

    return true;
  }

  Future<void> _registerUser() async {
    String uname = _usernameController.text.trim();
    String pass = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      var userCheck = await FirebaseFirestore.instance
          .collection('users')
          .doc(uname)
          .get();

      if (userCheck.exists) {
        throw "Username already taken.";
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uname)
          .set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "username": uname,
        "password": _hashPassword(pass),
        "age": int.tryParse(_ageController.text) ?? 0,
        "gender": _selectedGender,
        "city": _cityController.text.trim(),
        "goal": _selectedGoal,
        "height": double.tryParse(_heightController.text) ?? 0.0,
        "weight": double.tryParse(_weightController.text) ?? 0.0,
        "avatar": _selectedAvatar,
        "isLoggedIn": true,
        "profileComplete": true,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainMenuPage(),
        ),
            (route) => false,
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _pickAvatar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const Text(
              "Choose your Avatar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 100,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1,
                ),
                itemCount: _avatars.length,
                itemBuilder: (context, index) {
                  bool isSelected =
                      _selectedAvatar == _avatars[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = _avatars[index];
                      });

                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.green
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        backgroundImage:
                        NetworkImage(_avatars[index]),
                        backgroundColor: AppColors.card,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_step > 0) {
                        setState(() => _step--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / 3,
                        minHeight: 5,
                        backgroundColor: AppColors.card,
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(
                          AppColors.green,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Text(
                    '${_step + 1} / 3',
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
              padding:
              const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    _step == 0
                        ? 'Create your\naccount.'
                        : _step == 1
                        ? 'About\nyour body.'
                        : 'Personalize\nyour profile.',
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
                        : _step == 1
                        ? 'Help us personalize your experience'
                        : 'Show us who you are',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 28),
                child: _step == 0
                    ? _stepOne()
                    : _step == 1
                    ? _stepTwo()
                    : _stepThree(),
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
        _field(
          'Full Name',
          _nameController,
          icon: Icons.badge_outlined,
        ),

        _field(
          'Username',
          _usernameController,
          icon: Icons.alternate_email_rounded,
        ),

        _field(
          'Email',
          _emailController,
          icon: Icons.mail_outline_rounded,
          keyboard: TextInputType.emailAddress,
        ),

        _field(
          'Password',
          _passwordController,
          icon: Icons.lock_outline_rounded,
          obscure: true,
        ),

        const SizedBox(height: 28),

        _nextButton(
          'Continue',
              () {
            if (_validateStep0()) {
              setState(() => _step = 1);
            }
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _stepTwo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                'Age',
                _ageController,
                icon: Icons.cake_outlined,
                keyboard: TextInputType.number,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _field(
                'City',
                _cityController,
                icon: Icons.location_city_outlined,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: _field(
                'Height (cm)',
                _heightController,
                icon: Icons.height_rounded,
                keyboard: TextInputType.number,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _field(
                'Weight (kg)',
                _weightController,
                icon: Icons.monitor_weight_outlined,
                keyboard: TextInputType.number,
              ),
            ),
          ],
        ),

        _dropdown(
          label: 'Gender',
          value: _selectedGender,
          items: ['male', 'female', 'other'],
          onChanged: (v) {
            setState(() => _selectedGender = v!);
          },
        ),

        const SizedBox(height: 16),

        _dropdown(
          label: 'Fitness Goal',
          value: _selectedGoal,
          items: [
            'Weight Loss',
            'Muscle Gain',
            'Endurance',
            'Yoga',
          ],
          onChanged: (v) {
            setState(() => _selectedGoal = v!);
          },
        ),

        const SizedBox(height: 28),

        _nextButton(
          'Continue',
              () {
            if (_validateStep1()) {
              setState(() => _step = 2);
            }
          },
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _stepThree() {
    return Column(
      children: [
        const SizedBox(height: 20),

        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.green,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.card,
                    backgroundImage:
                    NetworkImage(_selectedAvatar),
                  ),
                ),
              ),

              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        OutlinedButton.icon(
          onPressed: () {
            _showError("Gallery selection coming soon!");
          },
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text("Choose from Gallery"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(
              color: AppColors.card,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 60),

        _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.green,
          ),
        )
            : _nextButton(
          'Create Account',
          _registerUser,
        ),
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
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          filled: true,
          fillColor: AppColors.white,
          prefixIcon: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 19,
          ),
          suffixIcon: obscure
              ? GestureDetector(
            onTap: () {
              setState(() => _obscure = !_obscure);
            },
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
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 14,
          ),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          border: InputBorder.none,
        ),
        dropdownColor: AppColors.white,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        items: items
            .map(
              (g) => DropdownMenuItem(
            value: g,
            child: Text(g),
          ),
        )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _nextButton(
      String label,
      VoidCallback onTap,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greenDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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