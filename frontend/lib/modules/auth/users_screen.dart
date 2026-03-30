// lib/modules/auth/users_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/user_model.dart';

class UsersScreen extends StatefulWidget {
  final User admin;
  const UsersScreen({super.key, required this.admin});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _obtenerUsuarios();
  }

  // HU03: Listar Usuarios desde MongoDB (Render)
  Future<void> _obtenerUsuarios() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://puntoventa-3gn6.onrender.com/usuarios'),
        headers: {'Authorization': 'Bearer ${widget.admin.token}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          users = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error: $e");
    }
  }

  // --- FUNCIÓN PARA DARLE COLOR A LOS ROLES ---
  Color _getColorPorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return Colors.deepPurple;
      case 'vendedor':
        return Colors.teal;
      case 'consultor':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Gestión de Usuarios", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : users.isEmpty
          ? const Center(child: Text("No hay usuarios registrados", style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                final String username = u['Username'] ?? 'Sin nombre';
                final String role = u['Role'] ?? 'Desconocido';
                final Color roleColor = _getColorPorRol(role);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withOpacity(0.1),
                      radius: 25,
                      child: Text(
                        username.substring(0, 1).toUpperCase(), 
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 20)
                      ),
                    ),
                    title: Text(
                      username, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: roleColor.withOpacity(0.5))
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_square, color: Colors.grey),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Editar usuario: $username"))
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoRegistro(context),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text("Nuevo Usuario", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // HU02: Formulario de Registro (Corregido con Mayúsculas para Node.js)
  void _mostrarDialogoRegistro(BuildContext context) {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'Vendedor';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.indigo),
            SizedBox(width: 10),
            Text("Registrar Usuario"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl, 
              decoration: const InputDecoration(
                labelText: "Nombre de Usuario", 
                prefixIcon: Icon(Icons.person_outline)
              )
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passCtrl, 
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Contraseña", 
                prefixIcon: Icon(Icons.lock_outline)
              )
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Rol del Sistema",
                prefixIcon: Icon(Icons.admin_panel_settings_outlined)
              ),
              value: selectedRole,
              items: ['Administrador', 'Vendedor', 'Consultor']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => selectedRole = val!,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            onPressed: () async {
              // 1. Validar que no estén vacíos
              if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Llena todos los campos"), backgroundColor: Colors.red)
                );
                return;
              }

              try {
                // 2. Enviar petición a Render
                final res = await http.post(
                  Uri.parse('https://puntoventa-3gn6.onrender.com/usuarios'),
                  headers: {
                    'Content-Type': 'application/json', 
                    'Authorization': 'Bearer ${widget.admin.token}'
                  },
                  // 3. Variables idénticas a las que espera tu Node.js
                  body: jsonEncode({
                    'Username': userCtrl.text, 
                    'Password': passCtrl.text, 
                    'Role': selectedRole
                  }),
                );

                if (res.statusCode == 201 || res.statusCode == 200) {
                  _obtenerUsuarios(); // Refrescar lista visual
                  if (context.mounted) {
                    Navigator.pop(context); // Cierra la ventana
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("¡Usuario creado con éxito!"), backgroundColor: Colors.green)
                    );
                  }
                } else {
                  // Si el backend lo rechaza
                  if (context.mounted) {
                    // Intentar decodificar el mensaje de error del backend
                    String errorMsg = 'Error desconocido';
                    try {
                      errorMsg = jsonDecode(res.body)['message'] ?? errorMsg;
                    } catch (_) {
                      errorMsg = res.body;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $errorMsg"), backgroundColor: Colors.red)
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error de conexión: $e"), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text("Guardar Usuario"),
          )
        ],
      ),
    );
  }
}