import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Inicio",
    "Gestión de Usuarios",
    "Configuración del Sistema",
    "Reportes y Estadísticas",
    "Rutas o Viajes Reportados"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.indigo.shade900,
      ),
      drawer: Drawer(
        backgroundColor: Colors.indigo.shade50,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo.shade900),
              accountName: const Text("Administrador"),
              accountEmail: const Text("admin@patrulla.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: Colors.indigo, size: 40),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home,
              text: "Inicio",
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.people,
              text: "Gestión de Usuarios",
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              text: "Configuración del Sistema",
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.analytics,
              text: "Reportes y Estadísticas",
              index: 3,
            ),
            _buildDrawerItem(
              icon: Icons.map,
              text: "Rutas o Viajes Reportados",
              index: 4,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Cerrar Sesión"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required int index}) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.indigo.shade700 : Colors.grey.shade700),
      title: Text(
        text,
        style: TextStyle(
          color: _selectedIndex == index ? Colors.indigo.shade900 : Colors.black87,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      default:
        return Center(
          child: Text(
            "Sección: ${_titles[_selectedIndex]}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "👋 Bienvenido, Administrador",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Aquí puedes ver un resumen general del sistema y acceder a las configuraciones.",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 25),

          // Tarjetas de métricas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard("Usuarios", "254", Icons.people, Colors.blue),
              _buildStatCard("Rutas", "89", Icons.map, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard("Reportes", "45", Icons.report, Colors.red),
              _buildStatCard("Configuraciones", "12", Icons.settings, Colors.green),
            ],
          ),

          const SizedBox(height: 30),
          const Divider(thickness: 1.2),

          // Gráfico decorativo (de muestra)
          const SizedBox(height: 20),
          Center(
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: const Center(
                child: Text(
                  "📊 Gráfico de Actividad (ejemplo visual)",
                  style: TextStyle(color: Colors.indigo, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150,
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
