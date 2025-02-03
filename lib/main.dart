import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'splash_screen.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/splash': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
