import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Production Server
  static const String baseUrl = 'http://sobirovelmurod.uz/scada/api/';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}api.php?action=login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // Return the parsed JSON regardless of status so caller can
      // display server-provided messages. Caller will handle navigation
      // on success and show message on failure.
      return json;
    } else {
      throw Exception('Server Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    // Use api.php?action=get_status for Live Weather & Dual Gates
    final response = await http.get(
      Uri.parse('${baseUrl}api.php?action=get_status'),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        // Fixed: using 'success'
        return json['data']; // Allow full access to keys
      }
      throw Exception(json['message']);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> controlGate(
    String target,
    String command,
    int userId, {
    int? position,
  }) async {
    final Map<String, dynamic> bodyData = {
      'target': target,
      'command': command,
      'user_id': userId,
    };

    if (position != null) {
      bodyData['position'] = position;
    }

    final response = await http.post(
      Uri.parse('${baseUrl}api.php?action=control_gate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bodyData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to control gate: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getMessages() async {
    final response = await http.get(Uri.parse('${baseUrl}chat.php?limit=50'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['messages'];
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    int userId,
    String type,
    String content, {
    File? file,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('${baseUrl}chat.php'));
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
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  // --- User Management (Admin Only) ---

  Future<List<dynamic>> getUsers(int adminId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}api/users.php?action=list&user_id=$adminId'),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'success') {
        return json['users'];
      }
      throw Exception(json['message']);
    }
    throw Exception('Failed to load users: ${response.statusCode}');
  }

  Future<void> addUser(Map<String, dynamic> userData, int adminId) async {
    // Inject adminId for auth check
    final body = Map<String, dynamic>.from(userData);
    body['user_id'] = adminId;

    final response = await http.post(
      Uri.parse('${baseUrl}api/users.php?action=add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Server Error: ${response.statusCode}');
    }
    
    final json = jsonDecode(response.body);
    if (json['status'] != 'success') {
      throw Exception(json['message']);
    }
  }

  Future<void> deleteUser(int targetId, int adminId) async {
    final response = await http.post(
      Uri.parse('${baseUrl}api/users.php?action=delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': targetId,
        'user_id': adminId, // Auth
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server Error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json['status'] != 'success') {
      throw Exception(json['message']);
    }
  }
}
