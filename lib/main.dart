import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'home_screen/home_screen.dart';
import 'login_screen/login_screen.dart';
import 'signin_screen/signin_screen.dart';
import 'start_screen/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FreshCartApp());
}

class FreshCartApp extends StatefulWidget {
  const FreshCartApp({super.key});

  @override
  State<FreshCartApp> createState() => _FreshCartAppState();
}

class _FreshCartAppState extends State<FreshCartApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'FreshCart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFAF2),
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: FirebaseAuth.instance.currentUser == null
          ? StartScreen(onGetStarted: _pushLogin, onOpenSignIn: _pushSignIn)
          : const HomeScreen(),
    );
  }

  NavigatorState get _navigator => _navigatorKey.currentState!;

  void _pushLogin() {
    _navigator.push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(onCreateAccount: _pushSignIn),
      ),
    );
  }

  void _pushSignIn() {
    _navigator.push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }
}
