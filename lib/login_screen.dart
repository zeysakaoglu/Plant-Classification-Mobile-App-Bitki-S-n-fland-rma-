import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart'; // 💡 Ana ekran dosyasını eklemeyi unutma
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giriş başarılı!")),
      );

      // 🔁 Giriş sonrası yönlendirme
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Giriş başarısız";
      if (e.code == 'user-not-found') {
        message = "Kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        message = "Hatalı şifre.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              const Text(
                'Tarla Takip',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hesap oluşturun',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uygulamaya giriş yapmak için e-posta adresinizi girin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'email@domain.com',
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Şifre',
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(width: 2, color: Colors.black),
                    ),
                  ),
                  child: const Text("Giriş Yap"),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(width: 2, color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Kayıt Ol"),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.black)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("veya", style: TextStyle(color: Colors.black)),
                  ),
                  Expanded(child: Divider(color: Colors.black)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                child: const Text("Google ile devam et"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(width: 2, color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {},
                child: const Text("Apple ile devam et"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(width: 2, color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text.rich(
                TextSpan(
                  text: 'Devam ederek ',
                  children: [
                    TextSpan(
                      text: 'Hizmet Şartları',
                      style: TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                    ),
                    TextSpan(text: ' ve ', style: TextStyle(color: Colors.black)),
                    TextSpan(
                      text: 'Gizlilik Politikası',
                      style: TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                    ),
                    TextSpan(
                      text: 'nı kabul etmiş olursunuz.',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
