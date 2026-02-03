import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_screen.dart'; // 👉 Ana ekran yönlendirmesi için ekledik

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _tryRegister() async {
    String name = _nameController.text.trim();
    String surname = _surnameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || surname.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || _selectedDate == null) {
      _showError("Lütfen tüm alanları doldurun.");
      return;
    }

    if (password != confirmPassword) {
      _showError("Şifreler eşleşmiyor.");
      return;
    }

    if (password.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _showError("Şifre kurallarına uymuyor.");
      return;
    }

    String birthYear = _selectedDate!.year.toString();
    if (password.contains(birthYear)) {
      _showError("Şifre doğum yılınızı içermemeli.");
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'isim': name,
        'soyisim': surname,
        'email': email,
        'dogumTarihi': _selectedDate,
        'kayitTarihi': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt başarılı!")));

      // ✅ Kayıt sonrası ana ekrana yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError("Hata: ${e.message}");
    } catch (e) {
      _showError("Beklenmedik hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Kayıt Ol'), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'İsim', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _surnameController, decoration: const InputDecoration(labelText: 'Soyisim', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre Tekrar', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '⚠️ Şifre Kuralları:\n- En az 8 karakter\n- En az 1 büyük harf\n- En az 1 küçük harf\n- En az 1 sayı veya sembol (!@#...)\n- Doğum yılınızı içermemeli',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(8)),
                  width: double.infinity,
                  child: Text(
                    _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Doğum Tarihi Seç',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _tryRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Kayıt Ol', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
