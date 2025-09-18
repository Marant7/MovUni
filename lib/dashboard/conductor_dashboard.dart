import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart';
import '../profile_edit.dart';
import 'publicar_viaje.dart';
import 'historial_viajes.dart';

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

  void _verHistorialViajes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistorialViajesPage()),
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
                    _verHistorialViajes(context);
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¡Bienvenido Conductor!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  _abrirPublicarViaje(context);
                },
                child: const Text('Publicar Viaje'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistorialViajesPage(),
                    ),
                  );
                },
                child: const Text('Ver Historial de Viajes'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditPage(userType: 'Conductor'),
                    ),
                  );
                },
                child: const Text('Editar Perfil'),
              ),
            ],
          ),
        ),
      );
}