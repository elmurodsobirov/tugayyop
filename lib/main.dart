import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scada_mobile_app/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ScadaApp());
}

class ScadaApp extends StatelessWidget {
  const ScadaApp({super.key});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCADA PK-00',
      debugShowCheckedModeBanner: false,
      theme: ScadaTheme.darkTheme,
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.data == true) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
