import 'package:flutter/material.dart';

import 'login_screen/login_screen.dart';
import 'signin_screen/signin_screen.dart';
import 'start_screen/start_screen.dart';

void main() {
  runApp(const FreshCartApp());
}

class FreshCartApp extends StatefulWidget {
  const FreshCartApp({super.key});

  @override
  State<FreshCartApp> createState() => _FreshCartAppState();
}

class _FreshCartAppState extends State<FreshCartApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  UserProfileData? _registeredUser;

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
      home: StartScreen(onGetStarted: _pushLogin, onOpenSignIn: _pushSignIn),
    );
  }

  NavigatorState get _navigator => _navigatorKey.currentState!;

  void _pushLogin() {
    _navigator.push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          registeredUser: _registeredUser,
          onCreateAccount: _pushSignIn,
        ),
      ),
    );
  }

  void _pushSignIn() {
    _navigator.push(
      MaterialPageRoute(
        builder: (_) => SignInScreen(
          onAccountCreated: (user) {
            setState(() {
              _registeredUser = user;
            });
            _navigator.pop();
            ScaffoldMessenger.of(_navigator.context).showSnackBar(
              const SnackBar(content: Text('Account created. Please login.')),
            );
          },
        ),
      ),
    );
  }
}

class UserProfileData {
  const UserProfileData({
    required this.name,
    required this.phoneNumber,
    required this.password,
  });

  final String name;
  final String phoneNumber;
  final String password;
}
