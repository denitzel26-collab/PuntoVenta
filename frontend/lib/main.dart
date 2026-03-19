import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'modules/auth/users_screen.dart';

void main() => runApp(const PuntoVentaApp());

class PuntoVentaApp extends StatelessWidget {
  const PuntoVentaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- PANTALLA DE LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _mostrarSnack(String msj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj)));
  }

  Future<void> _intentarLogin() async {
    setState(() => _isLoading = true);
    
    final user = await _authService.login(_userController.text, _passController.text);
    
    setState(() => _isLoading = false);

    if (user != null) {
      _mostrarSnack("¡Bienvenido ${user.username}!");
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(user: user)),
      );
    } else {
      _mostrarSnack("Usuario o contraseña incorrectos o servidor offline");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person, size: 70, color: Colors.indigo),
                const SizedBox(height: 20),
                const Text("Tech Store Login", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextField(
                  controller: _userController, 
                  decoration: const InputDecoration(labelText: "Usuario", border: OutlineInputBorder())
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passController, 
                  obscureText: true, 
                  decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder())
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _intentarLogin,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text("INGRESAR"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- PANTALLA PRINCIPAL (DASHBOARD) ---
class DashboardScreen extends StatelessWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  // Corregido: Ahora recibe el context para poder mostrar el SnackBar
  void _mostrarSnack(BuildContext context, String msj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msj)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Tech Store"), 
        backgroundColor: Colors.indigo.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const LoginScreen())
            )
          )
        ]
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bienvenido, ${user.username}", 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Rol: ${user.role}", 
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 40),
            const Text("Módulos Disponibles:", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),

            // --- MÓDULO 1: GESTIÓN DE USUARIOS ---
            ListTile(
              leading: const Icon(Icons.people, color: Colors.indigo),
              title: const Text("Gestión de Usuarios (Módulo 1)"),
              subtitle: const Text("HU02 y HU03: Registrar y listar"),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.indigo.withOpacity(0.05),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsersScreen(admin: user)),
                );
              },
            ),

            const SizedBox(height: 15),

            // --- MÓDULO 4: REPORTES ---
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text("Reportes de Ventas (Módulo 4)"),
              subtitle: const Text("HU18: Generar PDF y Excel"),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.red.withOpacity(0.05),
              onTap: () {
                _mostrarSnack(context, "Abriendo generador de reportes...");
                // Aquí conectarás la lógica de descarga de PDF/Excel
              },
            ),
          ],
        ),
      ),
    );
  }
}