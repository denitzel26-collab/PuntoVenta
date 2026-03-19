import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/user_model.dart';

class UsersScreen extends StatefulWidget {
  final User admin; // Necesitamos el token del admin
  const UsersScreen({super.key, required this.admin});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List users = [];

  @override
  void initState() {
    super.initState();
    _obtenerUsuarios();
  }

  // HU03: Listar Usuarios desde MongoDB
  Future<void> _obtenerUsuarios() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/usuarios'),
      headers: {'Authorization': 'Bearer ${widget.admin.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Usuarios (Módulo 1)")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final u = users[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(u['Username'] ?? 'Sin nombre'),
            subtitle: Text("Rol: ${u['Role']}"),
            trailing: const Icon(Icons.edit, size: 20),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _mostrarDialogoRegistro(context),
      ),
    );
  }

  // HU02: Formulario de Registro (Diálogo rápido)
  void _mostrarDialogoRegistro(BuildContext context) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Vendedor';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registrar Nuevo Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Usuario")),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['Administrador', 'Vendedor', 'Consultor'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => selectedRole = val!,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              // Aquí va el POST a /usuarios de tu Node.js
              final res = await http.post(
                Uri.parse('http://localhost:3000/usuarios'),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.admin.token}'},
                body: jsonEncode({'username': userCtrl.text, 'password': passCtrl.text, 'role': selectedRole}),
              );
              if (res.statusCode == 201) {
                _obtenerUsuarios(); // Refrescar lista
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }
}