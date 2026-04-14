import 'package:flutter/material.dart';
import 'package:frontend/services/ticket_service.dart';
import 'package:intl/intl.dart';
import '../../models/producto_model.dart';
import '../../models/venta_model.dart';
import '../../services/api_productos.dart';
import '../../services/api_ventas.dart';

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
  
  // Variables de Pago
  String metodoPago = 'Efectivo';
  final _pagaConCtrl = TextEditingController();
  final _numTarjetaCtrl = TextEditingController();
  double cambio = 0;

  final Color mlBlue = Color.fromARGB(255, 78, 128, 202);

  void _agregarAlCarrito(Producto p) {
    if (p.stock <= 0) return;
    setState(() {
      int index = carrito.indexWhere((item) => item.productId == p.id);
      if (index != -1) {
        if (carrito[index].quantity < p.stock) {
          carrito[index] = VentaItem(
            productId: p.id,
            name: p.nombre,
            priceAtSale: p.precio,
            quantity: carrito[index].quantity + 1,
          );
        }
      } else {
        carrito.add(VentaItem(productId: p.id, name: p.nombre, priceAtSale: p.precio, quantity: 1));
      }
      _actualizarTotales();
    });
  }

  void _actualizarTotales() {
    total = carrito.fold(0, (sum, item) => sum + (item.priceAtSale * item.quantity));
    _calcularCambio(_pagaConCtrl.text);
  }

  void _calcularCambio(String val) {
    double entrega = double.tryParse(val) ?? 0;
    setState(() {
      cambio = entrega > total ? entrega - total : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: mlBlue,
        title: Text("Punto de Venta - MercadoTienda"),
        elevation: 0,
      ),
      body: Row(
        children: [
          // COLUMNA IZQUIERDA: TICKET Y PAGO (40% de la pantalla)
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: _buildPanelVenta(),
          ),
          
          // COLUMNA DERECHA: CATÁLOGO (65% de la pantalla)
          Expanded(
            child: Column(
              children: [
                _buildBuscador(),
                Expanded(child: _buildGridProductos()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelVenta() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("RESUMEN DE VENTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: mlBlue)),
          Divider(),
          // Lista de productos seleccionados
          Expanded(
            child: ListView.builder(
              itemCount: carrito.length,
              itemBuilder: (context, i) {
                final item = carrito[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name, style: TextStyle(fontSize: 13)),
                  subtitle: Text("${item.quantity} x \$${item.priceAtSale}"),
                  trailing: Text("\$${(item.quantity * item.priceAtSale).toStringAsFixed(2)}"),
                );
              },
            ),
          ),
          Divider(thickness: 2),
          // SECCIÓN DE PAGO
          _buildSeccionPago(),
          SizedBox(height: 10),
          // BOTÓN FINAL
          ElevatedButton(
            onPressed: carrito.isEmpty ? null : _confirmarVenta,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 162, 133, 185),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("FINALIZAR Y TICKET (\$${total.toStringAsFixed(2)})", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPago() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: metodoPago,
          decoration: InputDecoration(labelText: "Método de Pago"),
          items: ['Efectivo', 'Tarjeta'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) => setState(() => metodoPago = val!),
        ),
        if (metodoPago == 'Efectivo') ...[
          TextField(
            controller: _pagaConCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "¿Con cuánto paga?", prefixText: "\$ "),
            onChanged: _calcularCambio,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("CAMBIO:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("\$ ${cambio.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ] else ...[
          TextField(
            controller: _numTarjetaCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Número de Tarjeta", hintText: "**** **** **** 1234"),
          ),
        ],
      ],
    );
  }

  Widget _buildBuscador() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (val) => setState(() => busqueda = val),
        decoration: InputDecoration(
          hintText: "Buscar por nombre de producto...",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildGridProductos() {
    return FutureBuilder<List<Producto>>(
      future: _apiProd.fetchProductos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final filtrados = snapshot.data!.where((p) => p.nombre.toLowerCase().contains(busqueda.toLowerCase())).toList();
        
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10
          ),
          itemCount: filtrados.length,
          itemBuilder: (context, i) {
            final p = filtrados[i];
            return Card(
              child: InkWell(
                onTap: () => _agregarAlCarrito(p),
                child: Column(
                  children: [
                    Expanded(child: Icon(Icons.inventory, size: 40, color: mlBlue)),
                    Text(p.nombre, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("\$${p.precio}", style: TextStyle(color: mlBlue)),
                    Text("Stock: ${p.stock}", style: TextStyle(fontSize: 10, color: p.stock < 5 ? Colors.red : Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarVenta() async {
    if (carrito.isEmpty) return;

  // 1. Crear el objeto venta
  Venta v = Venta(
    userId: "vendedor_001", 
    items: carrito, 
    paymentMethod: metodoPago, 
    totalAmount: total
  );

  // 2. Enviar a Railway
  final res = await _apiVentas.registrarVenta(v);

  if (res['success']) {
    // 3. SI LA VENTA FUE EXITOSA, GENERAR PDF
    await TicketService.generarTicket(
      items: carrito,
      total: total,
      metodo: metodoPago,
      pagoCon: double.tryParse(_pagaConCtrl.text) ?? total,
      cambio: cambio,
    );

    _mostrarExito();
  } else {
    // Si Railway nos dice que el stock falló, lo mostramos
    _mostrarError("Error: ${res['message']}");
  }// Aquí invocarás la lógica de api_ventas y luego el generador de PDF
    
  }

  void _mostrarExito() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Venta Exitosa"), backgroundColor: Colors.green));
    setState(() { carrito.clear(); _pagaConCtrl.clear(); _numTarjetaCtrl.clear(); total = 0; cambio = 0; });
  }
  
  void _mostrarError(String s) {}
}