import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  String errorMessage = '';

  Future<void> _signIn() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacementNamed(context, '/splash');
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'An error occurred.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Oturum Aç")),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.quiz, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Şifre"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signIn,
                child: const Text("Oturum Aç"),
              ),
              TextButton(
                onPressed: () {
                  // Yeni Üye Ol butonuna basıldığında SignUpScreen'e yönlendirme yapılacak
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text("Yeni Üye Ol"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
