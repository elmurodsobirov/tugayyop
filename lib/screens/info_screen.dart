import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return Scaffold(
      appBar: AppBar(title: const Text('Information')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: apiService.fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final employees = snapshot.data?['employees'] as List<dynamic>? ?? [];
          final schedule = snapshot.data?['schedule'] as List<dynamic>? ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text('Employees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              ...employees.map((e) => ListTile(
                leading: CircleAvatar(backgroundImage: e['photo_url'] != null ? NetworkImage(e['photo_url']) : null, child: e['photo_url'] == null ? const Icon(Icons.person) : null),
                title: Text(e['name']),
                subtitle: Text('${e['position']} • ${e['phone']}'),
              )),
              const SizedBox(height: 20),
              const Text('Operation Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [DataColumn(label: Text('Day')), DataColumn(label: Text('Open')), DataColumn(label: Text('Close'))],
                  rows: schedule.map<DataRow>((s) => DataRow(cells: [
                    DataCell(Text(s['day'])),
                    DataCell(Text(s['open'])),
                    DataCell(Text(s['close'])),
                  ])).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
