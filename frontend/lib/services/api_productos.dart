import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; // IMPORTANTE: Para que XFile funcione
import '../models/producto_model.dart';

class ApiProductos {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "https://apiventas-5dxn.onrender.com",
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<List<Producto>> fetchProductos() async {
    try {
      final res = await _dio.get('/productos');
      return (res.data as List).map((p) => Producto.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchCategorias() async {
    try {
      final res = await _dio.get('/categorias');
      return res.data;
    } catch (e) {
      return [];
    }
  }

  // SUBIDA DE IMAGEN
  Future<String?> subirImagen(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final res = await _dio.post('/upload-imagen', data: formData);
      
      // Corrección aplicada: tu API en Python devuelve la llave "url", no "url_imagen"
      return res.data['url']; 
    } catch (e) {
      print("Error subiendo imagen: $e");
      return null;
    }
  }

  Future<bool> crearProducto(Map<String, dynamic> data) async {
    try {
      await _dio.post('/productos', data: data);
      return true;
    } catch (e) { 
      return false; 
    }
  }

  Future<bool> modificarProducto(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/productos/$id', data: data);
      return true;
    } catch (e) { 
      return false; 
    }
  }

  Future<bool> eliminarProducto(int id) async {
    try {
      await _dio.delete('/productos/$id');
      return true;
    } catch (e) {
      print("Error eliminando: $e");
      return false;
    }
  }

  Future<bool> crearCategoria(String nombre) async {
    try {
      await _dio.post('/categorias', data: {"nombre": nombre});
      return true;
    } catch (e) { 
      return false; 
    }
  }

  Future<bool> eliminarCategoria(int id) async {
    try {
      await _dio.delete('/categorias/$id');
      return true;
    } catch (e) { 
      return false; 
    }
  }
}