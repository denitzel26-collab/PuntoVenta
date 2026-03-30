import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../dashboard/dashboard_screen.dart'; // Asegúrate de que esta ruta sea correcta

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
      // Navegación limpia y sin errores de const
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(user: user)),
      );
    } else {
      _mostrarSnack("Usuario o contraseña incorrectos");
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