class Producto {
  final int id;
  final String nombre;
  final double precio;
  final int stock;
  final String descripcion;
  final String? urlImagen;
  final int? idCategoria;
  final bool activo; // <-- NUEVO CAMPO

  Producto({
    required this.id, 
    required this.nombre, 
    required this.precio, 
    required this.stock, 
    required this.descripcion,
    this.urlImagen,
    this.idCategoria,
    required this.activo, // <-- REQUERIDO
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id_producto'],
      nombre: json['nombre'],
      precio: json['precio'].toDouble(),
      stock: json['cantidad_stock'] ?? 0,
      descripcion: json['descripcion'] ?? 'Sin descripción',
      urlImagen: json['url_imagen'],
      idCategoria: json['id_categoria'],
      activo: json['activo'] ?? true, // <-- CAPTURAMOS EL ESTADO
    );
  }
}