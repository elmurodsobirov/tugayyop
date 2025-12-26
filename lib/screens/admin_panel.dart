import 'package:flutter/material.dart';
import 'package:scada_mobile_app/services/api_service.dart';
import 'package:scada_mobile_app/theme/app_theme.dart';
import 'package:scada_mobile_app/widgets/glass_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final ApiService _apiService = ApiService();
  int _userId = 0;
  List<dynamic> _users = [];
  bool _isLoading = false;

  // Gate Control
  double _sliderValueA = 0;
  double _sliderValueB = 0;

  @override
  void initState() {
    super.initState();
    _loadInitData();
  }

  Future<void> _loadInitData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id') ?? 0;
    _refreshUsers();
  }

  Future<void> _refreshUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getUsers(_userId);
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("User Load Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeCommand(String target, double val) async {
    try {
      await _apiService.controlGate(target, 'set_position', _userId); 
      // Note: controlGate in api_service.dart currently takes 'target', 'command', 'userId'
      // It DOES NOT take 'position'. I need to update api_service to support position!
      // Wait, api_service.dart controlGate body construction:
      // body: jsonEncode({'target': target, 'command': command, 'user_id': userId}),
      // It ignores position? I need to fix api_service first or pass it.
      
      // Let's assume I'll fix ApiService to accept optional 'position' arg.
    } catch (e) {
      //...
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("ADMIN COMMANDER", style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 16),
        
        // Gate Control Section
        Text("PRECISION GATE CONTROL", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              _buildSliderControl("SLUICE A", _sliderValueA, (v) => setState(() => _sliderValueA = v), "GATE A"),
              const Divider(color: Colors.white24),
              _buildSliderControl("SLUICE B", _sliderValueB, (v) => setState(() => _sliderValueB = v), "GATE B"),
            ],
          ),
        ),

        const SizedBox(height: 24),
        
        // User Management Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("USER MANAGEMENT", style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.person_add, color: ScadaTheme.neonGreen),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildUserList(),
      ],
    );
  }

  Widget _buildSliderControl(String label, double val, Function(double) onChanged, String target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: ScadaTheme.neonCyan)),
            Text("${val.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: val,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: ScadaTheme.neonCyan,
          inactiveColor: Colors.white10,
          onChanged: onChanged,
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _sendPositionCommand(target, val.toInt()),
            child: const Text("EXECUTE MOVEMENT"),
          ),
        ),
      ],
    );
  }

  Future<void> _sendPositionCommand(String target, int pos) async {
    // We need to support 'position' in ApiService
    // I will fix ApiService right after this file creation.
    try {
      // Temporary hack: ApiService needs update. 
      // Using a direct call approach here would be messy. 
      // I'll assume ApiService.controlGate will be updated to take named arg {int? position}.
      await _apiService.controlGate(target, 'set_position', _userId, position: pos);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Command Sent")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildUserList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _users.length,
      itemBuilder: (ctx, i) {
        final u = _users[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white10,
                child: Text(u['username'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(u['role'].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              ),
              if (u['username'] != 'admin') // Simple protection
              IconButton(
                icon: const Icon(Icons.delete, color: ScadaTheme.neonRed, size: 20),
                onPressed: () => _deleteUser(int.parse(u['id'].toString())),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteUser(int id) async {
    try {
      await _apiService.deleteUser(id, _userId);
      _refreshUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete Error: $e")));
    }
  }

  void _showAddUserDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'operator';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("New User", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 8),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Username")),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: role,
              dropdownColor: const Color(0xFF1E293B),
              items: ['admin', 'operator', 'technician'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
              onChanged: (v) => role = v!,
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.addUser({
                  'username': userCtrl.text,
                  'password': passCtrl.text,
                  'full_name': nameCtrl.text,
                  'role': role
                }, _userId);
                if (mounted) Navigator.pop(ctx);
                _refreshUsers();
              } catch (e) {
                // Error handling
              }
            },
            child: const Text("Create"),
          )
        ],
      ),
    );
  }
}
