import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'map_screen.dart';
import 'chat_screen.dart';
import 'info_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  Timer? _timer;

  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchData();
    // Poll data every 5 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _fetchData(),
    );
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString('role') ?? 'Unknown';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> _controlGate(String command, String target) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) return;

    try {
      final result = await _apiService.controlGate(target, command, userId);

      if (result['success'] == true) {
        _fetchData(); // Refresh immediately
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$target: $command command sent')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Command failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SCADA PK-00 Dashboard', style: TextStyle(fontSize: 18)),
            Text(
              'Role: ${_userRole.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildMetastationCard(),
                    const SizedBox(height: 16),
                    const Text(
                      'Control Panel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildGateCard('A', 'Canal Sluice A (Chap)'),
                    const SizedBox(height: 10),
                    _buildGateCard('B', 'Canal Sluice B (O\'ng)'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text('View Satellite Map'),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MapScreen(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Support Chat'),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatScreen(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.info),
                      label: const Text('Employees & Schedule'),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InfoScreen(),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildGateCard(String key, String title) {
    final gate = _data?['gates']?[key];
    final sensors = _data?['sensors']?[key];

    if (gate == null) return const SizedBox.shrink();

    final status = gate['status'] ?? 'Unknown';
    // Logic update: Shlyuz Sathi (Level) is now gate position (sm)
    final position = gate['position'] ?? 0; // Use Gate Position as Level
    // Flow rate from sensors
    final flow = sensors?['flow_rate'] ?? 0.0;

    Color statusColor = Colors.grey;
    if (status == 'open') {
      statusColor = Colors.green;
    } else if (status == 'closed') {
      statusColor = Colors.red;
    } else if (status == 'moving' ||
        status == 'opening' ||
        status == 'closing') {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${status.toUpperCase()}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('Level: $position sm'), // Updated unit
                    Text('Flow: $flow m³/s'),
                  ],
                ),
                CircularProgressIndicator(
                  value:
                      (position is int
                          ? position.toDouble()
                          : double.tryParse(position.toString()) ?? 0) /
                      100,
                  backgroundColor: Colors.grey[200],
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _controlGate('open', 'GATE $key'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'OPEN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _controlGate('close', 'GATE $key'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetastationCard() {
    final meta = _data?['metastation'];
    final current = meta?['current'];

    if (current == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Weather Data Loading...'),
        ),
      );
    }

    return Card(
      color: Colors.blue[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PK-00 Weather Station',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Divider(color: Colors.white54),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _weatherItem(
                  Icons.thermostat,
                  '${current['temperature_2m']}${meta['current_units']['temperature_2m']}',
                  'Temp',
                ),
                _weatherItem(
                  Icons.water_drop,
                  '${current['relative_humidity_2m']}${meta['current_units']['relative_humidity_2m']}',
                  'Humid',
                ),
                _weatherItem(
                  Icons.air,
                  '${current['wind_speed_10m']} km/h',
                  'Wind',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _weatherItem(
                  Icons.speed,
                  '${current['pressure_msl']} hPa',
                  'Pressure',
                ),
                _weatherItem(
                  Icons.cloud,
                  '${current['cloud_cover']}%',
                  'Clouds',
                ),
                _weatherItem(
                  Icons.visibility,
                  'High',
                  'Vis',
                ), // OpenMeteo doesn't always send Vis, just placeholder
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
