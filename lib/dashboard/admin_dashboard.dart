import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart';

// 🔹 Páginas administrativas
import 'admin_users_page.dart';
import 'admin_viajes_page.dart';
import 'admin_solicitudes_page.dart';
import 'admin_notificaciones_page.dart';

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

  // 🔹 Variables de métricas
  int totalUsers = 0;
  int totalTrips = 0;
  int totalRequests = 0;
  int totalNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // 🔹 Cargar datos desde Firebase
  Future<void> _loadDashboardData() async {
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final tripsSnap = await FirebaseFirestore.instance.collection('viajes').get();
    final requestsSnap = await FirebaseFirestore.instance.collection('solicitudes_viajes').get();
    final notifSnap = await FirebaseFirestore.instance.collection('notificaciones').get();

    setState(() {
      totalUsers = usersSnap.size;
      totalTrips = tripsSnap.size;
      totalRequests = requestsSnap.size;
      totalNotifications = notifSnap.size;
    });
  }

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

            // ====== MENÚ LATERAL ======
            _buildDrawerItem(
              icon: Icons.home,
              text: "Inicio",
              index: 0,
            ),

            ListTile(
              leading: const Icon(Icons.people, color: Colors.indigo),
              title: const Text("Gestión de Usuarios"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminUsersPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.request_page, color: Colors.purple),
              title: const Text("Gestión de Solicitudes"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminSolicitudesPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.red),
              title: const Text("Gestión de Notificaciones"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminNotificacionesPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.map, color: Colors.orange),
              title: const Text("Gestión de Viajes"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminViajesPage()),
                );
              },
            ),

            const Divider(),

            // ====== CERRAR SESIÓN ======
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

  // === Construir los items del menú lateral ===
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: _selectedIndex == index ? Colors.indigo.shade700 : Colors.grey.shade700,
      ),
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

  // === Construir el contenido del cuerpo principal ===
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

  // === CONTENIDO DEL INICIO (MÉTRICAS Y RESUMEN) ===
  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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

            // ==== TARJETAS DE MÉTRICAS REAL ====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Usuarios", "$totalUsers", Icons.people, Colors.blue),
                _buildStatCard("Viajes", "$totalTrips", Icons.map, Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Solicitudes", "$totalRequests", Icons.request_page, Colors.purple),
                _buildStatCard("Notificaciones", "$totalNotifications", Icons.notifications, Colors.red),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1.2),

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
      ),
    );
  }

  // === Tarjeta para mostrar estadísticas ===
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150,
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
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
