import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../models/user_model.dart';
import '../auth/users_screen.dart'; 
import '../auth/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final User user;
  const DashboardScreen({super.key, required this.user});

  // URL base de tu backend en Render
  final String _backendUrl = 'https://puntoventa-3gn6.onrender.com/reportes/ventas';

  // Función para abrir la URL de descarga de reportes
  Future<void> _descargarReporte(String tipoReporte) async {
    final String solicitante = Uri.encodeComponent(user.username);
    final Uri url = Uri.parse('$_backendUrl/$tipoReporte?solicitante=$solicitante');

    if (!await launchUrl(url)) {
      debugPrint('No se pudo abrir la URL: $url');
    }
  }

  void _mostrarMenuPerfil(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Perfil de Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${user.username}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Rol: ${user.role}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); 
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = user.role.toLowerCase() == 'administrador';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.account_circle, size: 30),
          onPressed: () => _mostrarMenuPerfil(context),
        ),
        title: const Center(
          child: Text('SISTEMA DE GESTIÓN DE ELECTRÓNICA (SOA)', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        actions: [
          const SizedBox(width: 48), 
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PANEL IZQUIERDO: PRODUCTOS ---
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      width: double.infinity,
                      child: const Text('Catálogo de Productos', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: 9, 
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory, size: 50, color: Colors.grey),
                                const SizedBox(height: 10),
                                Text('Producto ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('\$${(index + 1) * 150}.00', style: const TextStyle(color: Colors.green)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),

            // --- PANEL DERECHO: VENTAS Y REPORTES ---
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Ventas Recientes', 
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                if (isAdmin)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.download, color: Colors.indigo),
                                    tooltip: 'Descargar Reportes',
                                    onSelected: (String result) {
                                      _descargarReporte(result);
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'pdf',
                                        child: ListTile(
                                          leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                                          title: Text('Reporte PDF'),
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'excel',
                                        child: ListTile(
                                          leading: Icon(Icons.table_chart, color: Colors.green),
                                          title: Text('Reporte Excel'),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: 20, 
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.attach_money, color: Colors.white, size: 18),
                                  ),
                                  title: Text('Venta #${1000 + index}'),
                                  subtitle: const Text('Completado - Efectivo'),
                                  trailing: Text('\$${(index + 1) * 200}.00', 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.people),
                        label: const Text('Gestión de Usuarios', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => UsersScreen(admin: user)),
                          );
                        },
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}