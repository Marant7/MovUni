import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movuni/services/auth_service.dart';
import 'package:movuni/services/session_service.dart';
import '../login.dart';
import '../profile_edit.dart';
import 'publicar_viaje.dart';
import 'historial_viajes.dart';

class ConductorDashboard extends StatefulWidget {
  const ConductorDashboard({Key? key}) : super(key: key);

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  final SessionService _sessionService = SessionService();
  final User? user = FirebaseAuth.instance.currentUser;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    // Aquí deberías obtener los datos del usuario desde tu servicio
    setState(() {
      _userName = "Nombre del Conductor";
    });
  }

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

  void _logout() async {
    final sessionService = SessionService();
    await sessionService.clearUserRole();
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _manejarSolicitud(String requestId, String status, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .doc(requestId)
          .update({
        'status': status,
        'fecha_respuesta': FieldValue.serverTimestamp(),
      });

      // Cerrar el modal
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud $status correctamente'),
          backgroundColor: status == 'aceptada' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al $status la solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarModalSolicitud(BuildContext context, DocumentSnapshot request) {
    final origen = request['origen']['nombre'] ?? 'Origen';
    final destino = request['destino']['nombre'] ?? 'Destino';
    final hora = request['hora'] ?? '';
    final passengerId = request['passenger_id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(passengerId).get(),
          builder: (context, snapshot) {
            String passengerName = 'Pasajero';
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!;
              passengerName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
            }

            return AlertDialog(
              title: const Text('Solicitud de Viaje'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pasajero: $passengerName'),
                  const SizedBox(height: 8),
                  Text('Ruta: $origen → $destino'),
                  const SizedBox(height: 8),
                  Text('Hora: $hora'),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Qué deseas hacer con esta solicitud?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => _manejarSolicitud(request.id, 'rechazada', context),
                  child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () => _manejarSolicitud(request.id, 'aceptada', context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        title: const Text('MOVUNI - Conductor'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de bienvenida
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[100],
                        child: Icon(
                          Icons.directions_car,
                          size: 30,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, $_userName',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Modo Conductor activado',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Solicitudes pendientes
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('solicitudes_viajes')
                    .where('conductor_id', isEqualTo: user?.uid)
                    .where('status', isEqualTo: 'pendiente')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final pendingRequests = snapshot.data!.docs;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solicitudes Pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingRequests.length,
                          itemBuilder: (context, index) {
                            final request = pendingRequests[index];
                            final origen = request['origen']['nombre'] ?? 'Origen';
                            final destino = request['destino']['nombre'] ?? 'Destino';
                            final hora = request['hora'] ?? '';
                            final passengerId = request['passenger_id'];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(passengerId).get(),
                              builder: (context, snapshot) {
                                String passengerName = 'Pasajero';
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final data = snapshot.data!;
                                  passengerName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    title: Text('$origen → $destino'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Pasajero: $passengerName'),
                                        Text('Hora: $hora'),
                                      ],
                                    ),
                                    leading: const Icon(Icons.person, color: Colors.blue),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onTap: () => _mostrarModalSolicitud(context, request),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  
                  return const SizedBox();
                },
              ),
              
              // Opciones del conductor
              const Text(
                'Opciones de Conductor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 15),
              
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.2,
                  ),
                  children: [
                    _DriverOptionCard(
                      title: 'Publicar Viaje',
                      icon: Icons.add_road,
                      color: Colors.blue,
                      onTap: () => _abrirPublicarViaje(context),
                    ),
                    _DriverOptionCard(
                      title: 'Mis Viajes',
                      icon: Icons.list_alt,
                      color: Colors.green,
                      onTap: () {
                        // Navegar a la pantalla de mis viajes
                      },
                    ),
                    _DriverOptionCard(
                      title: 'Historial',
                      icon: Icons.history,
                      color: Colors.purple,
                      onTap: () => _verHistorialViajes(context),
                    ),
                    _DriverOptionCard(
                      title: 'Perfil',
                      icon: Icons.person,
                      color: Colors.teal,
                      onTap: () => _editarPerfil(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para las opciones del conductor
class _DriverOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DriverOptionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}