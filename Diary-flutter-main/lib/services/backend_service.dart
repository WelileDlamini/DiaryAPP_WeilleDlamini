import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  // Change this to your server URL
  static const String baseUrl = 'http://10.0.2.2/mydiary_backend/api/';
  // For physical device: http://YOUR_IP_ADDRESS/mydiary_backend/api/
  // For emulator: http://10.0.2.2/mydiary_backend/api/

  // Auth endpoints
  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${baseUrl}login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Diary entries endpoints
  static Future<Map<String, dynamic>> saveEntry(Map<String, dynamic> entry) async {
    final response = await http.post(
      Uri.parse('${baseUrl}save_entry.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getEntries(int userId) async {
    final response = await http.get(
      Uri.parse('${baseUrl}get_entries.php?user_id=$userId'),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteEntry(int entryId, int userId) async {
    final response = await http.post(
      Uri.parse('${baseUrl}delete_entry.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'entry_id': entryId,
        'user_id': userId,
      }),
    );
    return jsonDecode(response.body);
  }
}