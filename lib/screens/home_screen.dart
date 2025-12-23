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

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Poll data every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchData());
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

  Future<void> _controlGate(String action) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) return;

    try {
      await _apiService.controlGate(_data?['gate']['id'] ?? 1, action, userId);
      _fetchData(); // Refresh immediately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gate $action command sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        title: const Text('SCADA PK-00 Dashboard'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildGateStatusCard(),
                  const SizedBox(height: 16),
                  _buildMetastationCard(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('View Satellite Map'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Support Chat'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.info),
                    label: const Text('Employees & Schedule'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InfoScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGateStatusCard() {
    final status = _data?['gate']['status'] ?? 'Unknown';
    final flow = _data?['gate']['flow_rate'] ?? 0.0;
    
    Color statusColor = Colors.grey;
    if (status == 'open') statusColor = Colors.green;
    else if (status == 'closed') statusColor = Colors.red;
    else if (status == 'opening' || status == 'closing') statusColor = Colors.orange;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Sluice Gate Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(status.toUpperCase(), style: TextStyle(fontSize: 24, color: statusColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Flow Rate: $flow m³/s'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _controlGate('open'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('OPEN', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => _controlGate('close'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('CLOSE', style: TextStyle(color: Colors.white)),
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
    final params = meta?['parameters'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metastation Data (${meta?['source']})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            if (params != null) ...[
              Text('Temperature: ${params['T2M']}°C'),
              Text('Humidity: ${params['RH2M']}%'),
              Text('Wind Speed: ${params['WS2M']} m/s'),
            ] else
              const Text('No data available'),
          ],
        ),
      ),
    );
  }
}
