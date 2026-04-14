import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/venta_model.dart';
// AGREGA ESTA LÍNEA (Ruta relativa):

class ApiVentas {
  // Cambia esto por tu URL real de Railway
  final String baseUrl = "https://apiusuarios-production-1861.up.railway.app";

  // HU13, HU14, HU15: Registrar una venta y descontar stock
  Future<Map<String, dynamic>> registrarVenta(Venta nuevaVenta) async {
    final url = Uri.parse('$baseUrl/ventas');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(nuevaVenta.toJson()),
      );

      final decodedResponse = json.decode(response.body);

      if (response.statusCode == 201) {
        // Venta exitosa
        return {"success": true, "message": "Venta registrada con éxito"};
      } else if (response.statusCode == 400) {
        // Aquí capturamos el error de stock insuficiente que viene de Render a través de Railway
        return {
          "success": false, 
          "message": decodedResponse['error'] ?? "Error al procesar la venta"
        };
      } else {
        return {"success": false, "message": "Error del servidor: ${response.statusCode}"};
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  // HU16: Consultar ventas realizadas (Historial)
  Future<List<Venta>> obtenerHistorialVentas() async {
    final url = Uri.parse('$baseUrl/ventas');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Venta.fromJson(data)).toList();
      } else {
        throw Exception('Fallo al cargar el historial de ventas');
      }
    } catch (e) {
      throw Exception('Error de red: $e');
    }
  }
}