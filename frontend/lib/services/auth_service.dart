import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  // URL de tu backend publicado en Render
  final String baseUrl = "https://puntoventa-3gn6.onrender.com/auth"; 

  Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        // Enviamos 'user' porque así lo pide tu req.body en Node
        body: jsonEncode({
          'user': username, 
          'password': password
        }), 
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Verificamos que el servidor mandó el token
        if (data.containsKey('token')) {
          // Si tu backend no manda el objeto 'user' completo, 
          // lo creamos con el role que sí viene en tu JSON
          return User(
            username: username,
            role: data['role'] ?? 'Vendedor',
            token: data['token'],
          );
        }
      }
      return null;
    } catch (e) {
      print("Error detallado: $e");
      return null;
    }
  }
}