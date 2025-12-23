import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator to access localhost
  static const String baseUrl = 'http://sobirovelmurod.uz/scada/api';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to connect to server');
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse('$baseUrl/data.php'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> controlGate(int gateId, String action, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/control.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'gate_id': gateId, 'action': action, 'user_id': userId}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to control gate');
    }
  }

  Future<List<dynamic>> getMessages() async {
    final response = await http.get(Uri.parse('$baseUrl/chat.php?limit=50'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['messages'];
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<Map<String, dynamic>> sendMessage(int userId, String type, String content, {File? file}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/chat.php'));
    request.fields['user_id'] = userId.toString();
    request.fields['type'] = type;
    request.fields['content'] = content;

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final stream = await request.send();
    final response = await http.Response.fromStream(stream);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }
}
