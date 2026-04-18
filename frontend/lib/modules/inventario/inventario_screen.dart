import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/producto_model.dart';
import '../../services/api_productos.dart';

class GestionInventario extends StatefulWidget {
  const GestionInventario({super.key});

  @override
  _GestionInventarioState createState() => _GestionInventarioState();
}

class _GestionInventarioState extends State<GestionInventario>
    with SingleTickerProviderStateMixin {
  final ApiProductos _api = ApiProductos();
  late TabController _tabController;

  Future<List<Producto>>? _productosFuture;
  Future<List<dynamic>>? _categoriasFuture;
  List<dynamic> _listaCategorias = [];

  // --- VARIABLES PARA EL FILTRO Y BÚSQUEDA ---
  String _busqueda = '';
  int? _categoriaFiltroSeleccionada;

  final Color mlBlue = const Color(0xFF3483FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(
      () => setState(() {}),
    ); // Actualiza el FAB y estado al cambiar de tab
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _productosFuture = _api.fetchProductos();
      _categoriasFuture = _api.fetchCategorias().then((cats) {
        _listaCategorias = cats;
        return cats;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _notificar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================
  // UI PRINCIPAL
  // ==========================================
  @override
  // ==========================================
  // UI PRINCIPAL (RESPONSIVA)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Obtenemos el ancho de la pantalla para saber si estamos en PC o Móvil
    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esPantallaGrande =
        anchoPantalla > 800; // Si pasa de 800px, lo tratamos como PC

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: mlBlue,
        elevation: 0,
        // 1. FLECHA DE REGRESAR A LA IZQUIERDA
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Cierra la pantalla
        ),
        // 2. TÍTULO RESPONSIVO
        title: Text(
          "Gestión de Inventario",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            // Si es pantalla grande el texto será 22, si es móvil será 18
            fontSize: esPantallaGrande ? 20 : 18,
          ),
        ),
        // 3. LOGO A LA DERECHA
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              // Aquí dejé un ícono de tienda temporal.
              // Si tienes tu logo en los assets, cámbialo por:
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                height: 35,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: "PRODUCTOS"),
            Tab(icon: Icon(Icons.category), text: "CATEGORÍAS"),
          ],
        ),
      ),
      // 4. CONSTRAINED BOX PARA QUE EN PC NO SE ESTIRE TODA LA PANTALLA
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ), // Ancho máximo de 1000px
          child: TabBarView(
            controller: _tabController,
            children: [_buildTabProductos(), _buildTabCategorias()],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mlBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? "Nuevo Producto" : "Nueva Categoría",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            if (_listaCategorias.isEmpty) {
              _notificar(
                "Primero debes crear al menos una categoría",
                Colors.orange,
              );
            } else {
              _mostrarFormularioProducto();
            }
          } else {
            _mostrarFormularioCategoria();
          }
        },
      ),
    );
  }

  // ==========================================
  // TAB PRODUCTOS CON FILTROS
  // ==========================================

  // ==========================================
  // TAB PRODUCTOS CON FILTROS, HOVER Y DETALLE AL CLIC
  // ==========================================
  Widget _buildTabProductos() {
    return Column(
      children: [
        // 1. BARRA DE BÚSQUEDA Y CHIPS DE CATEGORÍAS
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _busqueda = val),
                decoration: InputDecoration(
                  hintText: "Buscar producto...",
                  prefixIcon: Icon(Icons.search, color: mlBlue),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChipCategoria(null, "Todos"),
                    ..._listaCategorias
                        .map(
                          (cat) => _buildChipCategoria(
                            cat['id_categoria'],
                            cat['nombre'],
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2. LISTA DE PRODUCTOS CON PULL TO REFRESH Y ANIMACIÓN
        Expanded(
          child: FutureBuilder<List<Producto>>(
            future: _productosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return const Center(
                  child: Text("No hay productos registrados"),
                );

              final listaFiltrada = snapshot.data!.where((p) {
                final coincideNombre = p.nombre.toLowerCase().contains(
                  _busqueda.toLowerCase(),
                );
                final coincideCategoria =
                    _categoriaFiltroSeleccionada == null ||
                    p.idCategoria == _categoriaFiltroSeleccionada;
                return coincideNombre && coincideCategoria;
              }).toList();

              if (listaFiltrada.isEmpty)
                return const Center(
                  child: Text("Ningún producto coincide con tu búsqueda"),
                );

              return RefreshIndicator(
                color: mlBlue,
                onRefresh: () async => _cargarDatos(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(15).copyWith(bottom: 80),
                  itemCount: listaFiltrada.length,
                  itemBuilder: (context, i) {
                    final p = listaFiltrada[i];
                    bool isHovered = false;

                    return StatefulBuilder(
                      builder: (context, setStateItem) {
                        return MouseRegion(
                          onEnter: (_) => setStateItem(() => isHovered = true),
                          onExit: (_) => setStateItem(() => isHovered = false),
                          cursor: SystemMouseCursors.click,
                          child: AnimatedScale(
                            scale: isHovered ? 1.02 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: Opacity(
                              opacity: p.activo ? 1.0 : 0.6,
                              child: Card(
                                elevation: isHovered ? 8 : 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isHovered
                                        ? mlBlue.withOpacity(0.5)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                // AQUI ESTÁ EL CAMBIO: INKWELL PARA DETECTAR EL CLIC
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _mostrarDetalleProducto(
                                    p,
                                  ), // Abre el detalle
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  p.urlImagen != null &&
                                                      p.urlImagen!.isNotEmpty
                                                  ? Image.network(
                                                      p.urlImagen!,
                                                      width: 70,
                                                      height: 70,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, e, s) =>
                                                          _iconoPorDefecto(),
                                                    )
                                                  : _iconoPorDefecto(),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    p.nombre,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text: "Categoría: ",
                                                          style: TextStyle(
                                                            color: mlBlue,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              _obtenerNombreCategoria(
                                                                p.idCategoria,
                                                              ),
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Descripción: ",
                                                    style: TextStyle(
                                                      color: mlBlue,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    p.descripcion.isNotEmpty
                                                        ? p.descripcion
                                                        : "Sin descripción",
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "\$${p.precio.toStringAsFixed(2)}",
                                                        style: TextStyle(
                                                          color: mlBlue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        "Stock: ${p.stock}",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: p.stock < 5
                                                              ? Colors.red
                                                              : Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: p.activo
                                                    ? Colors.green.withOpacity(
                                                        0.1,
                                                      )
                                                    : Colors.red.withOpacity(
                                                        0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p.activo
                                                    ? "Activo"
                                                    : "Inactivo",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: p.activo
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Transform.scale(
                                                  scale: 0.8,
                                                  child: Switch(
                                                    value: p.activo,
                                                    activeColor: mlBlue,
                                                    onChanged: (bool valor) async {
                                                      bool exito = await _api
                                                          .modificarProducto(
                                                            p.id,
                                                            {
                                                              "nombre":
                                                                  p.nombre,
                                                              "descripcion":
                                                                  p.descripcion,
                                                              "precio":
                                                                  p.precio,
                                                              "cantidad_inicial":
                                                                  p.stock,
                                                              "url_imagen":
                                                                  p.urlImagen,
                                                              "id_categoria":
                                                                  p.idCategoria,
                                                              "activo": valor,
                                                            },
                                                          );
                                                      if (exito) {
                                                        _cargarDatos();
                                                      } else {
                                                        _notificar(
                                                          "Error al actualizar estado",
                                                          Colors.red,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                                IconButton(
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  onPressed: () =>
                                                      _mostrarFormularioProducto(
                                                        productoAEditar: p,
                                                      ),
                                                ),
                                                IconButton(
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 8,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _confirmarEliminacion(
                                                        "Producto",
                                                        p.nombre,
                                                        () async {
                                                          bool
                                                          exito = await _api
                                                              .eliminarProducto(
                                                                p.id,
                                                              );
                                                          if (exito) {
                                                            _notificar(
                                                              "Producto eliminado",
                                                              Colors.green,
                                                            );
                                                            _cargarDatos();
                                                          } else {
                                                            _notificar(
                                                              "Error al eliminar",
                                                              Colors.red,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- WIDGET PARA LOS BOTONES DE CATEGORÍA ---
  Widget _buildChipCategoria(int? id, String nombre) {
    bool isSelected = _categoriaFiltroSeleccionada == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(nombre),
        selected: isSelected,
        selectedColor: mlBlue.withOpacity(0.2),
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? mlBlue : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          setState(() {
            _categoriaFiltroSeleccionada = val ? id : null;
          });
        },
      ),
    );
  }

  Widget _iconoPorDefecto() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: mlBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.inventory_2, color: mlBlue),
    );
  }

  // Busca el nombre de la categoría en la lista usando el ID del producto
  String _obtenerNombreCategoria(int? idCat) {
    if (idCat == null) return "Sin categoría";
    final cat = _listaCategorias.firstWhere(
      (c) => c['id_categoria'] == idCat,
      orElse: () => null,
    );
    return cat != null ? cat['nombre'] : "Desconocida";
  }

  // ==========================================
  // VISTA DETALLE DEL PRODUCTO
  // ==========================================
  void _mostrarDetalleProducto(Producto p) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 450, // Ancho ideal para verse bien en PC y móvil
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen en grande
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: p.urlImagen != null && p.urlImagen!.isNotEmpty
                        ? Image.network(
                            p.urlImagen!,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _iconoPorDefectoGrande(),
                          )
                        : _iconoPorDefectoGrande(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: p.activo
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.activo ? "Activo" : "Inactivo",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: p.activo ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Categoría: ${_obtenerNombreCategoria(p.idCategoria)}",
                          style: TextStyle(
                            color: mlBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Descripción",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          p.descripcion.isNotEmpty
                              ? p.descripcion
                              : "Este producto no tiene descripción.",
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Precio de Venta",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "\$${p.precio.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      color: mlBlue,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "Stock Disponible",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "${p.stock} unidades",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: p.stock < 5
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cerrar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Ícono grande por si no hay imagen
  Widget _iconoPorDefectoGrande() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(color: mlBlue.withOpacity(0.1)),
      child: Icon(Icons.inventory_2, color: mlBlue, size: 80),
    );
  }
  // ==========================================
  // TAB CATEGORÍAS
  // ==========================================

  Widget _buildTabCategorias() {
    return FutureBuilder<List<dynamic>>(
      future: _categoriasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text("No hay categorías registradas"));

        return ListView.builder(
          padding: const EdgeInsets.all(15).copyWith(bottom: 80),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) {
            final cat = snapshot.data![i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: mlBlue.withOpacity(0.1),
                  child: Icon(Icons.category, color: mlBlue),
                ),
                title: Text(
                  cat['nombre'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmarEliminacion(
                    "Categoría",
                    cat['nombre'],
                    () async {
                      bool exito = await _api.eliminarCategoria(
                        cat['id_categoria'],
                      );
                      if (exito) {
                        _notificar("Categoría eliminada", Colors.green);
                        _cargarDatos();
                      } else {
                        _notificar(
                          "No se puede eliminar (Tiene productos asignados)",
                          Colors.red,
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ==========================================
  // FORMULARIO PRODUCTO (CREAR / EDITAR) CON VALIDACIONES
  // ==========================================
  void _mostrarFormularioProducto({Producto? productoAEditar}) {
    final _formKey = GlobalKey<FormState>();
    final _nombreCtrl = TextEditingController(
      text: productoAEditar?.nombre ?? "",
    );
    final _descCtrl = TextEditingController(
      text: productoAEditar?.descripcion ?? "",
    );
    final _precioCtrl = TextEditingController(
      text: productoAEditar?.precio.toString() ?? "",
    );
    final _stockCtrl = TextEditingController(
      text: productoAEditar?.stock.toString() ?? "",
    );

    // Si estamos editando y tiene categoría, la selecciona. Si es nuevo, selecciona la primera por defecto.
    int? _categoriaSeleccionada =
        productoAEditar?.idCategoria ??
        (_listaCategorias.isNotEmpty
            ? _listaCategorias.first['id_categoria']
            : null);

    String? _urlImagenActual = productoAEditar?.urlImagen;
    bool _estaActivo = productoAEditar?.activo ?? true;
    bool _subiendoImagen = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                productoAEditar == null ? "Nuevo Producto" : "Editar Producto",
                style: TextStyle(color: mlBlue, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SECCIÓN DE IMAGEN
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _subiendoImagen
                            ? const Center(child: CircularProgressIndicator())
                            : _urlImagenActual != null &&
                                  _urlImagenActual!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _urlImagenActual!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.error),
                                ),
                              )
                            : const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Seleccionar Imagen"),
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setStateDialog(() => _subiendoImagen = true);
                            String? url = await _api.subirImagen(image);
                            setStateDialog(() {
                              _urlImagenActual = url;
                              _subiendoImagen = false;
                            });
                            if (url == null)
                              _notificar("Error al subir imagen", Colors.red);
                          }
                        },
                      ),
                      const Divider(),

                      // CAMPO: NOMBRE DEL PRODUCTO
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nombre del Producto",
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return "El nombre es requerido";
                          if (v.trim().length < 3) return "Mínimo 3 caracteres";
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // CAMPO: DESCRIPCIÓN
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: "Descripción",
                          isDense: true,
                        ),
                         minLines: 2, // mínimo de líneas visibles
                      maxLines: null,// Le damos 2 líneas para que sea más cómodo escribir
                      ),
                      const SizedBox(height: 10),

                      // FILA: PRECIO Y STOCK
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _precioCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: "Precio",
                                prefixText: "\$ ",
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Requerido";
                                final num = double.tryParse(v);
                                if (num == null || num <= 0)
                                  return "Debe ser mayor a 0";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: "Stock",
                                isDense: true,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Requerido";
                                final num = int.tryParse(v);
                                if (num == null || num < 0) return "No válido";
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // SELECTOR DE CATEGORÍA
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Categoría",
                          isDense: true,
                        ),
                        value: _categoriaSeleccionada,
                        items: _listaCategorias.map<DropdownMenuItem<int>>((
                          cat,
                        ) {
                          return DropdownMenuItem<int>(
                            value: cat['id_categoria'],
                            child: Text(cat['nombre']),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => _categoriaSeleccionada = val),
                        validator: (v) =>
                            v == null ? "Selecciona una categoría" : null,
                      ),
                      const SizedBox(height: 10),

                      // INTERRUPTOR DE ACTIVO/INACTIVO
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Producto Activo",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          "Mostrar a los clientes en la tienda",
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _estaActivo,
                        activeColor: mlBlue,
                        onChanged: (val) =>
                            setStateDialog(() => _estaActivo = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: mlBlue),
                  onPressed: () async {
                    // SE EJECUTAN LAS VALIDACIONES AQUÍ
                    if (_formKey.currentState!.validate() &&
                        _categoriaSeleccionada != null) {
                      Navigator.pop(
                        context,
                      ); // Cierra el diálogo antes de guardar para no trabar la UI

                      // Prepara los datos a enviar a la API
                      Map<String, dynamic> payload = {
                        "nombre": _nombreCtrl.text.trim(),
                        "descripcion": _descCtrl.text.trim(),
                        "precio": double.parse(_precioCtrl.text),
                        "cantidad_inicial": int.parse(_stockCtrl.text),
                        "url_imagen": _urlImagenActual,
                        "id_categoria": _categoriaSeleccionada,
                        "activo": _estaActivo,
                      };

                      bool exito;
                      if (productoAEditar == null) {
                        exito = await _api.crearProducto(payload);
                        _notificar(
                          exito ? "Producto Creado" : "Error al crear producto",
                          exito ? Colors.green : Colors.red,
                        );
                      } else {
                        exito = await _api.modificarProducto(
                          productoAEditar.id,
                          payload,
                        );
                        _notificar(
                          exito
                              ? "Producto Actualizado"
                              : "Error al actualizar producto",
                          exito ? Colors.green : Colors.red,
                        );
                      }

                      if (exito)
                        _cargarDatos(); // Recarga la tabla para mostrar los cambios
                    }
                  },
                  child: Text(
                    productoAEditar == null ? "Guardar" : "Actualizar",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // FORMULARIO CATEGORÍA (CREAR)
  // ==========================================
  void _mostrarFormularioCategoria() {
    final TextEditingController _nombreCatCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Nueva Categoría",
            style: TextStyle(color: mlBlue, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _nombreCatCtrl,
            decoration: const InputDecoration(
              labelText: "Nombre de la categoría",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: mlBlue),
              onPressed: () async {
                if (_nombreCatCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  bool exito = await _api.crearCategoria(
                    _nombreCatCtrl.text.trim(),
                  );
                  if (exito) {
                    _notificar("Categoría creada", Colors.green);
                    _cargarDatos();
                  } else {
                    _notificar("Error al crear categoría", Colors.red);
                  }
                }
              },
              child: const Text(
                "Guardar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // DIÁLOGO DE CONFIRMACIÓN (REUTILIZABLE)
  // ==========================================
  void _confirmarEliminacion(
    String tipo,
    String nombre,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Confirmar Eliminación",
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          "¿Estás seguro de que deseas eliminar $tipo: '$nombre'?\nEsta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
