import 'package:flutter/material.dart';
import 'modules/auth/login_screen.dart'; 

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
      home: const LoginScreen(),
    );
  }
}