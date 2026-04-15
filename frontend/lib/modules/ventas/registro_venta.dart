import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para FilteringTextInputFormatter
import '../../models/producto_model.dart';
import '../../models/venta_model.dart';
import '../../services/api_productos.dart';
import '../../services/api_ventas.dart';
import '../../services/ticket_service.dart';

class RegistroVenta extends StatefulWidget {
  @override
  _RegistroVentaState createState() => _RegistroVentaState();
}

class _RegistroVentaState extends State<RegistroVenta> {
  final ApiProductos _apiProd = ApiProductos();
  final ApiVentas _apiVentas = ApiVentas();
  
  List<VentaItem> carrito = [];
  String busqueda = '';
  double total = 0;
  
  String metodoPago = 'Efectivo';
  final TextEditingController _pagaConCtrl = TextEditingController();
  final TextEditingController _numTarjetaCtrl = TextEditingController();
  double cambio = 0;

  final Color mlBlue = const Color(0xFF3483FA);

  @override
  void dispose() {
    _pagaConCtrl.dispose();
    _numTarjetaCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE CANTIDADES ---

  void _modificarCantidad(int productId, int cambioCantidad, int stockMaximo) {
    setState(() {
      int index = carrito.indexWhere((item) => item.productId == productId);
      if (index != -1) {
        int nuevaCantidad = carrito[index].quantity + cambioCantidad;

        if (nuevaCantidad > stockMaximo) {
          _notificar("Solo hay $stockMaximo unidades en stock", Colors.orange);
          nuevaCantidad = stockMaximo;
        }

        if (nuevaCantidad <= 0) {
          carrito.removeAt(index);
        } else {
          carrito[index] = VentaItem(
            productId: carrito[index].productId,
            name: carrito[index].name,
            priceAtSale: carrito[index].priceAtSale,
            quantity: nuevaCantidad,
          );
        }
      }
      _recalcularTotal();
    });
  }

  void _agregarAlCarrito(Producto p) {
    if (p.stock <= 0) {
      _notificar("Producto sin stock", Colors.red);
      return;
    }
    
    int index = carrito.indexWhere((item) => item.productId == p.id);
    if (index != -1) {
      _modificarCantidad(p.id, 1, p.stock);
    } else {
      setState(() {
        carrito.add(VentaItem(
          productId: p.id, 
          name: p.nombre, 
          priceAtSale: p.precio, 
          quantity: 1
        ));
        _recalcularTotal();
      });
    }
  }

  void _recalcularTotal() {
    total = carrito.fold(0, (sum, item) => sum + (item.priceAtSale * item.quantity));
    _actualizarCambio(_pagaConCtrl.text);
  }

  void _actualizarCambio(String valor) {
    double entrega = double.tryParse(valor) ?? 0;
    setState(() {
      cambio = (entrega > total) ? entrega - total : 0;
    });
  }

  bool _esVentaValida() {
    if (carrito.isEmpty) return false;
    if (metodoPago == 'Efectivo') {
      double entrega = double.tryParse(_pagaConCtrl.text) ?? 0;
      return entrega >= total && _pagaConCtrl.text.isNotEmpty;
    }
    return _numTarjetaCtrl.text.length >= 16;
  }

  void _confirmarVenta() async {
    Venta nuevaVenta = Venta(
      userId: "Vendedor_001",
      items: carrito,
      paymentMethod: metodoPago,
      totalAmount: total,
    );

    final resultado = await _apiVentas.registrarVenta(nuevaVenta);

    if (resultado['success']) {
      await TicketService.generarTicket(
        items: List.from(carrito),
        total: total,
        metodo: metodoPago,
        pagoCon: double.tryParse(_pagaConCtrl.text) ?? total,
        cambio: cambio,
      );
      _notificar("Venta Exitosa", Colors.green);
      _limpiarFormulario();
    } else {
      _notificar("Error: ${resultado['message']}", Colors.red);
    }
  }

  void _limpiarFormulario() {
    setState(() {
      carrito.clear();
      _pagaConCtrl.clear();
      _numTarjetaCtrl.clear();
      total = 0;
      cambio = 0;
    });
  }

  void _notificar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
     appBar: AppBar(
        backgroundColor: mlBlue,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Si la imagen no carga, muestra un icono por defecto
              return const Icon(Icons.store, color: Colors.white);
            },
          ),
        ),
        title: const Text(
          "Punto de Venta", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
      ),
      body: Row(
        children: [
          // PANEL IZQUIERDO: TICKET
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Text("TICKET DE VENTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mlBlue)),
                  const Divider(),
                  Expanded(
                    child: carrito.isEmpty 
                      ? const Center(child: Text("Agrega productos del catálogo")) 
                      : _buildListaCarrito(),
                  ),
                  const Divider(thickness: 2),
                  _buildCamposPago(),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _esVentaValida() ? _confirmarVenta : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      disabledBackgroundColor: Colors.grey[300],
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text("FINALIZAR COBRO \$${total.toStringAsFixed(2)}", 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          // PANEL DERECHO: CATÁLOGO
          Expanded(
            child: Column(
              children: [
                _buildBarraBusqueda(),
                Expanded(child: _buildGridProductos()),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildListaCarrito() {
  return FutureBuilder<List<Producto>>(
    future: _apiProd.fetchProductos(),
    builder: (context, snapshot) {
      return ListView.separated(
        itemCount: carrito.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, i) {
          final item = carrito[i];
          
          // Obtenemos el stock real del producto desde la API
          int stockMax = snapshot.data?.firstWhere(
            (p) => p.id == item.productId, 
            orElse: () => Producto(id: 0, nombre: '', precio: 0, stock: 99)
          ).stock ?? 99;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text("\$${item.priceAtSale} c/u"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                  onPressed: () => _modificarCantidad(item.productId, -1, stockMax),
                ),
                
                // --- CAMPO DE CANTIDAD CON VALIDACIÓN EN TIEMPO REAL ---
                SizedBox(
                  width: 60, // Un poco más ancho para que no se corte el número
                  child: TextFormField(
                    key: Key("${item.productId}_${item.quantity}"), 
                    initialValue: item.quantity.toString(),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                    // SE ACTIVA AL ESCRIBIR CADA NÚMERO
                    onChanged: (valor) {
                      if (valor.isEmpty) return; // Permitimos que borre para escribir otro
                      
                      int nueva = int.tryParse(valor) ?? 1;

                      // VALIDACIÓN CRÍTICA: Bloqueo de Stock
                      if (nueva > stockMax) {
                        _notificar("¡Error! Solo hay $stockMax disponibles", Colors.red);
                        // Forzamos el redibujo al máximo permitido
                        _modificarCantidad(item.productId, stockMax - item.quantity, stockMax);
                        return;
                      }

                      if (nueva <= 0) {
                        _modificarCantidad(item.productId, 1 - item.quantity, stockMax);
                        return;
                      }

                      // Si el número es válido y diferente al actual, actualizamos
                      if (nueva != item.quantity) {
                        _modificarCantidad(item.productId, nueva - item.quantity, stockMax);
                      }
                    },
                  ),
                ),
                
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
                  onPressed: () => _modificarCantidad(item.productId, 1, stockMax),
                ),
                const SizedBox(width: 5),
                Text("\$${(item.quantity * item.priceAtSale).toStringAsFixed(2)}", 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      );
    }
  );
}
  

  Widget _buildCamposPago() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: metodoPago,
            decoration: const InputDecoration(labelText: "Método de Pago", border: InputBorder.none),
            items: ['Efectivo', 'Tarjeta'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() {
              metodoPago = val!;
              _pagaConCtrl.clear();
              cambio = 0;
            }),
          ),
          if (metodoPago == 'Efectivo') ...[
            TextField(
              controller: _pagaConCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              decoration: const InputDecoration(labelText: "Efectivo recibido", prefixText: "\$ "),
              onChanged: _actualizarCambio,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Cambio:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("\$${cambio.toStringAsFixed(2)}", 
                     style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ] else ...[
            TextField(
              controller: _numTarjetaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 16,
              decoration: const InputDecoration(labelText: "Número de Tarjeta", counterText: "", hintText: "xxxx xxxx xxxx xxxx"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (val) => setState(() => busqueda = val),
        decoration: InputDecoration(
          hintText: "Buscar producto por nombre...",
          prefixIcon: Icon(Icons.search, color: mlBlue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildGridProductos() {
    return FutureBuilder<List<Producto>>(
      future: _apiProd.fetchProductos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final lista = snapshot.data!.where((p) => p.nombre.toLowerCase().contains(busqueda.toLowerCase())).toList();
        
        if (lista.isEmpty) return const Center(child: Text("No se encontraron productos"));

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final p = lista[i];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _agregarAlCarrito(p),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 45, color: mlBlue.withOpacity(0.7)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(p.nombre, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Text("\$${p.precio}", style: TextStyle(color: mlBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (p.stock < 5 ? Colors.red : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text("Stock: ${p.stock}", 
                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p.stock < 5 ? Colors.red : Colors.green[700])),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}