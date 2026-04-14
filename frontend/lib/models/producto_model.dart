class Producto {
  final int id;
  final String nombre;
  final double precio;
  final int stock;

  Producto({required this.id, required this.nombre, required this.precio, required this.stock});

  // Convierte el JSON de Render a un objeto de Flutter
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id_producto'],
      nombre: json['nombre'],
      precio: json['precio'].toDouble(),
      stock: json['cantidad_stock'] ?? 0,
    );
  }
}