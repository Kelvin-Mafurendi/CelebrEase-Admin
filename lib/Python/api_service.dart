import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  static const _baseUrl = 'http://192.168.0.110:5000/api';

  Future<Map<String, dynamic>> get fetchHelloMessage async {
    final response = await http.get(Uri.parse('$_baseUrl/hello'));
    if (response.statusCode == 200) {
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch hello message');
    }
  }
}