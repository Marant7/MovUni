import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart';
import '../profile_edit.dart';
import 'publicar_viaje.dart';

class ConductorDashboard extends StatelessWidget {
  const ConductorDashboard({Key? key}) : super(key: key);

  void _abrirPublicarViaje(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PublicarViajePage()),
    );
  }

  void _editarPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileEditPage(userType: 'Conductor'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF2F5FA),
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.directions_car, color: Colors.indigo, size: 30),
              SizedBox(width: 8),
              Text('MovUni', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.indigo, size: 30),
                      const SizedBox(width: 8),
                      const Text('MovUni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Inicio'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Buscar Viajes'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Publicar Viaje'),
                  onTap: () {
                    Navigator.pop(context);
                    _abrirPublicarViaje(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historial'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Mi Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    _editarPerfil(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Administración'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B63F6), Color(0xFF5B8CFF)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('¡Hola, Juan! 👋', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Bienvenido a MovUni, tu plataforma de movilidad universitaria', style: TextStyle(color: Colors.white70, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _infoCard(icon: Icons.directions_car_filled, label: 'Viajes conductor', value: '0'),
                  _infoCard(icon: Icons.groups_2, label: 'Viajes pasajero', value: '0', iconColor: Colors.green),
                ],
              ),
              Row(
                children: [
                  _infoCard(icon: Icons.star, label: 'Calificación', value: '4.8', iconColor: Colors.amber),
                  _infoCard(icon: Icons.calendar_today, label: 'Próximos viajes', value: '0', iconColor: Colors.deepOrange),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Acciones rápidas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Publicar viaje'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _abrirPublicarViaje(context),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar viaje'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {}, // Aquí puedes agregar lógica de búsqueda
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.route_outlined),
                      label: const Text('Mis rutas'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {}, // Aquí puedes agregar lógica de rutas
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _sectionCard(
                icon: Icons.directions_car,
                title: 'Mis próximos viajes',
                subtitle: 'No tienes viajes programados como conductor',
                iconColor: Colors.indigo,
              ),
              _sectionCard(
                icon: Icons.groups_2,
                title: 'Mis próximas reservas',
                subtitle: 'No tienes reservas activas como pasajero',
                iconColor: Colors.green,
              ),
              _sectionCard(
                icon: Icons.search,
                title: 'Viajes disponibles hoy',
                subtitle: 'No hay viajes disponibles para hoy. ¡Publica el tuyo!',
                iconColor: Colors.black54,
              ),
              _sectionCard(
                icon: Icons.calendar_today,
                title: 'Historial de viajes',
                subtitle: 'No tienes viajes en tu historial aún.',
                iconColor: Colors.deepPurple,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      );

  Widget _infoCard({required IconData icon, required String label, required String value, Color? iconColor}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? Colors.blue, size: 30),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? Colors.black87, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}