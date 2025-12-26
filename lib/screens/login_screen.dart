import 'package:flutter/material.dart';
import 'package:scada_mobile_app/screens/home_screen.dart';
import 'package:scada_mobile_app/services/api_service.dart';
import 'package:scada_mobile_app/theme/app_theme.dart';
import 'package:scada_mobile_app/widgets/glass_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      if (response['id'] == null) throw Exception("Login failed: missing ID");

      // Handle String or Int ID
      int uid;
      if (response['id'] is int) {
        uid = response['id'];
      } else {
        uid = int.tryParse(response['id'].toString()) ?? 0;
      }

      await prefs.setInt('user_id', uid);
      await prefs.setString('username', response['username'] ?? '');
      await prefs.setString('role', response['role'] ?? 'operator');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Access Denied', style: TextStyle(color: ScadaTheme.neonRed)),
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('RETRY'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ScadaTheme.neonCyan.withOpacity(0.2),
                boxShadow: [BoxShadow(color: ScadaTheme.neonCyan.withOpacity(0.4), blurRadius: 100)]
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScadaTheme.neonPurple.withOpacity(0.2),
                  boxShadow: [BoxShadow(color: ScadaTheme.neonPurple.withOpacity(0.4), blurRadius: 100)]
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, size: 60, color: ScadaTheme.neonCyan),
                    const SizedBox(height: 16),
                    Text(
                      'SCADA AUTH',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person, color: Colors.white54)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock, color: Colors.white54)),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ScadaTheme.neonCyan.withOpacity(0.1), 
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: ScadaTheme.neonCyan)
                            : const Text('INITIATE SESSION'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
