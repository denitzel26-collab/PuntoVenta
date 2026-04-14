import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto_model.dart';

class ApiProductos {
  final String baseUrl = "https://apiventas-5dxn.onrender.com";

  Future<List<Producto>> fetchProductos() async {
    final response = await http.get(Uri.parse('$baseUrl/productos'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Producto.fromJson(data)).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }
}