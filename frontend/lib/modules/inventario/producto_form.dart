import 'package:flutter/material.dart';
import '../../services/api_productos.dart';

class ProductoForm extends StatefulWidget {
  @override
  _ProductoFormState createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiProductos();

  // Controladores para capturar el texto
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      // Aquí llamarías a un método POST en api_productos.dart
      // que envíe: nombre, descripcion, precio, cantidad_inicial, id_categoria
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardando producto...')),
      );
      // Lógica de guardado...
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nuevo Producto (HU07)")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nombreCtrl, decoration: InputDecoration(labelText: "Nombre")),
              TextFormField(controller: _precioCtrl, decoration: InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
              TextFormField(controller: _stockCtrl, decoration: InputDecoration(labelText: "Stock Inicial"), keyboardType: TextInputType.number),
              TextFormField(controller: _descCtrl, decoration: InputDecoration(labelText: "Descripción")),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _guardar, child: Text("Dar de Alta"))
            ],
          ),
        ),
      ),
    );
  }
}