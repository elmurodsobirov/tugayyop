import 'package:flutter/material.dart';
import 'package:scada_mobile_app/screens/admin_panel.dart';
import 'package:scada_mobile_app/screens/chat_screen.dart';
import 'package:scada_mobile_app/screens/dashboard_view.dart';
import 'package:scada_mobile_app/screens/info_screen.dart';
import 'package:scada_mobile_app/screens/login_screen.dart';
import 'package:scada_mobile_app/screens/map_screen.dart';
import 'package:scada_mobile_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userRole = '';
  
  // Pages
  final List<Widget> _pages = [
    const DashboardView(),
    const MapScreen(),
    const ChatScreen(),
    // Admin or Info placeholder
    const Center(child: CircularProgressIndicator()),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'unknown';
      _updatePages();
    });
  }

  void _updatePages() {
    // If admin, 4th tab is AdminPanel.
    // If operator, 4th tab is InfoScreen (Profile/Schedule)
    Widget fourthPage = const InfoScreen();
    if (_userRole == 'admin') {
      fourthPage = const AdminPanel();
    }

    setState(() {
      _pages[3] = fourthPage;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.hub, color: ScadaTheme.neonCyan),
            const SizedBox(width: 8),
            Text('SCADA PK-00', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: ScadaTheme.neonRed)),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: const Border(top: BorderSide(color: ScadaTheme.glassBorder, width: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: ScadaTheme.quietDark,
          selectedItemColor: ScadaTheme.neonCyan,
          unselectedItemColor: Colors.white24,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Monitor'),
            const BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
            const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
            BottomNavigationBarItem(
              icon: Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.info_rounded),
              label: isAdmin ? 'Admin' : 'Info',
            ),
          ],
        ),
      ),
    );
  }
}
