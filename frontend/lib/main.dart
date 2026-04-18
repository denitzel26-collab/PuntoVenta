import 'package:flutter/material.dart';
import 'package:frontend/modules/inventario/inventario_screen.dart';
import 'package:frontend/modules/ventas/registro_venta.dart' hide GestionInventario;
void main() => runApp(const PuntoVentaApp());

class PuntoVentaApp extends StatelessWidget {
  const PuntoVentaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tech Store POS',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.grey[100], 
      ),
      home:  GestionInventario(),
    );
  }
}