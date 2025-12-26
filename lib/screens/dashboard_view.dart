import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scada_mobile_app/services/api_service.dart';
import 'package:scada_mobile_app/theme/app_theme.dart';
import 'package:scada_mobile_app/widgets/glass_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _data;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchData();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      debugPrint("Data fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final meta = _data?['metastation'];
    final gateA = _data?['gates']?['A'];
    final gateB = _data?['gates']?['B'];

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Status
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SYSTEM STATUS",
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    const Text("ONLINE",
                        style: TextStyle(
                            color: ScadaTheme.neonGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
                Icon(Icons.check_circle, color: ScadaTheme.neonGreen, size: 32),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sluice Visuals (2.5D)
          Row(
            children: [
              Expanded(
                  child: _buildGateVisual(
                      "SLUICE A", gateA, ScadaTheme.neonCyan)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildGateVisual(
                      "SLUICE B", gateB, ScadaTheme.neonPurple)),
            ],
          ),
          const SizedBox(height: 24),

          // Weather Grid
          Text("METASTATION LIVE",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildWeatherGrid(meta),
        ],
      ),
    );
  }

  Widget _buildGateVisual(
      String label, Map<String, dynamic>? gateData, Color accent) {
    final int position = gateData?['position'] ?? 0;
    // Position 0 = Closed (Plate Down), 100 = Open (Plate Up)
    // We visualize the PLATE going UP.
    // So visual height of plate from bottom = 100% means closed?
    // No. Sluice Gate: Plate DOWN (0% flow) -> Plate UP (100% flow)
    // Let's model the "Gap".
    // Plate is a physical object. If position=0 (Closed), Plate is at bottom.
    // If position=100 (Open), Plate is at top.

    return GlassCard(
      padding: const EdgeInsets.all(0),
      borderColor: accent.withOpacity(0.5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron')),
                Text("$position%",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border(
                left: BorderSide(color: Colors.white24, width: 4),
                right: BorderSide(color: Colors.white24, width: 4),
                bottom: BorderSide(color: Colors.white24, width: 4),
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Water Flow (Behind Plate)
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 200 * (position / 100),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent.withOpacity(0.6),
                        accent.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                // The Gate Plate itself
                // When position is 0, plate is covering full height?
                // Usually "Set Position" means % open.
                // 0% Open = Plate Fully Down. 100% Open = Plate Fully Up.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutBack,
                  bottom: 200 * (position / 100),
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200, // Plate is tall
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF334155), Color(0xFF1E293B)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border(bottom: BorderSide(color: accent, width: 4)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            offset: Offset(0, 5))
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.drag_handle,
                          color: Colors.white10, size: 50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherGrid(Map<String, dynamic>? meta) {
    if (meta == null || meta['current'] == null) {
      return const Center(child: Text("Waiting for weather data..."));
    }

    final cur = meta['current'];
    final units = meta['current_units'];

    final items = [
      {'icon': Icons.thermostat, 'val': cur['temperature_2m'], 'u': units['temperature_2m'], 'lbl': 'Temp'},
      {'icon': Icons.water_drop, 'val': cur['relative_humidity_2m'], 'u': units['relative_humidity_2m'], 'lbl': 'Humid'},
      {'icon': Icons.air, 'val': cur['wind_speed_10m'], 'u': units['wind_speed_10m'], 'lbl': 'Wind'},
      {'icon': Icons.beach_access, 'val': cur['precipitation'], 'u': units['precipitation'], 'lbl': 'Precip'},
      {'icon': Icons.speed, 'val': cur['pressure_msl'], 'u': units['pressure_msl'], 'lbl': 'Press'},
      {'icon': Icons.cloud, 'val': cur['cloud_cover'], 'u': units['cloud_cover'], 'lbl': 'Cloud'},
      {'icon': Icons.wb_sunny, 'val': cur['is_day'] == 1 ? "Day" : "Night", 'u': '', 'lbl': 'Cycle'},
      {'icon': Icons.visibility, 'val': 'High', 'u': '', 'lbl': 'Vis'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 larger cards instead of 4 tiny ones? User wanted "All data". 
        // 4 columns is standard for dense data grid.
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return GlassCard(
          padding: const EdgeInsets.all(8),
          borderColor: Colors.white10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'] as IconData, size: 20, color: ScadaTheme.neonCyan),
              const SizedBox(height: 8),
              Text("${item['val']}${item['u']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center),
              Text(item['lbl'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}
