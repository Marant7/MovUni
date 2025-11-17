import 'package:flutter/material.dart';
import 'package:movuni/services/auth_service.dart';
import 'package:movuni/services/session_service.dart';
import 'package:movuni/login.dart';
import 'package:movuni/screens/active_trips_screen.dart';
import 'package:movuni/screens/mis_reservas_screen.dart';
import 'package:movuni/screens/register_vehicle_screen.dart';
import 'package:movuni/dashboard/historial_viajes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/conductor_dashboard.dart';

class EstudianteDashboard extends StatefulWidget {
  const EstudianteDashboard({Key? key}) : super(key: key);

  @override
  State<EstudianteDashboard> createState() => _EstudianteDashboardState();
}

class _EstudianteDashboardState extends State<EstudianteDashboard> {
  final SessionService _sessionService = SessionService();
  final User? user = FirebaseAuth.instance.currentUser;
  String? _userName;
  bool _isDriver = false;
  String _driverStatus = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            if (_userName!.isEmpty) {
              _userName = userData['email']?.split('@')[0] ?? 'Estudiante';
            }
            
            // Cargar información del conductor
            _isDriver = userData['isDriver'] ?? false;
            _driverStatus = userData['driverStatus'] ?? '';

          });
        }
      } catch (e) {
        setState(() {
          _userName = 'Estudiante';
        });
      }
    }
  }

  void _cambiarAConductor(BuildContext context) async {
    // Si NO es conductor, mostrar diálogo para registrar vehículo
    if (!_isDriver) {
      _showRegisterVehicleDialog();
      return;
    }

    // Si es conductor, verificar que esté completamente verificado
    // Debe cumplir: vehicle.verified == true Y driverStatus == 'verified'
    bool isFullyVerified = _driverStatus == 'verified';
    
    if (!isFullyVerified) {
      _showVehicleNotVerifiedDialog();
      return;
    }

    // Si llegó aquí, está completamente verificado - cambiar a conductor
    try {
      await _sessionService.saveUserRole('conductor');
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ConductorDashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar a conductor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRegisterVehicleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue),
              SizedBox(width: 10),
              Expanded(child: Text('Registrar como conductor')),
            ],
          ),
          content: const Text(
            'Para ser conductor necesitas registrar tu vehículo y licencia de conducir. '
            'Después de registrar tus datos, un administrador verificará tu información '
            'antes de que puedas ofrecer viajes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterVehicleScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Registrar vehículo'),
            ),
          ],
        );
      },
    );
  }

  void _showVehicleNotVerifiedDialog() {
    String message = '';
    String title = '';
    IconData icon = Icons.pending;
    Color iconColor = Colors.orange;
    bool showUpdateButton = false;

    switch (_driverStatus) {
      case 'pending_verification':
        title = 'Verificación pendiente';
        message = 'Tu vehículo está en proceso de verificación por el administrador. '
                  'Te notificaremos cuando puedas comenzar a ofrecer viajes. '
                  'Por favor espera la aprobación.';
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange;
        break;
      case 'rejected':
        title = 'Verificación rechazada';
        message = 'Tu solicitud fue rechazada por el administrador. '
                  'Por favor, actualiza los datos de tu vehículo para una nueva revisión.';
        icon = Icons.cancel;
        iconColor = Colors.red;
        showUpdateButton = true;
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (_driverStatus == 'pending_verification') ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mientras tanto, puedes seguir buscando viajes como pasajero',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (showUpdateButton)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterVehicleScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[800],
                ),
                child: const Text('Actualizar datos'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
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

  void _verMisReservas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MisReservasScreen()),
    );
  }

  void _verHistorialEstudiante(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistorialEstudiantePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        title: const Text('MOVUNI - Estudiante'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
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
                    const Icon(Icons.school, color: Colors.indigo, size: 30),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveTripsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_seat),
                title: const Text('Mis Reservas'),
                onTap: () {
                  Navigator.pop(context);
                  _verMisReservas(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial'),
                onTap: () {
                  Navigator.pop(context);
                  _verHistorialEstudiante(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementar edición de perfil
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.directions_car,
                  color: _isDriver && _driverStatus == 'verified' 
                      ? Colors.green 
                      : Colors.blue,
                ),
                title: Row(
                  children: [
                    const Text('Cambiar a Conductor'),
                    if (_isDriver && (_driverStatus != 'verified')) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _driverStatus == 'rejected' ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _driverStatus == 'pending_verification' 
                                ? 'Pendiente' 
                                : (_driverStatus == 'rejected' ? 'Rechazado' : 'No verificado'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cambiarAConductor(context);
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
                          Icons.person,
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
                              'Hola, ${_userName ?? "Estudiante"}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Encuentra tu viaje ideal',
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

              // Banner de estado del conductor (si aplica)
              if (_isDriver && (_driverStatus != 'verified'))
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _driverStatus == 'rejected' 
                        ? Colors.red.shade50 
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _driverStatus == 'rejected' 
                          ? Colors.red.shade300 
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _driverStatus == 'rejected' ? Icons.cancel : Icons.hourglass_empty,
                        color: _driverStatus == 'rejected' ? Colors.red : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverStatus == 'rejected' 
                                  ? 'Solicitud de conductor rechazada' 
                                  : 'Solicitud de conductor en revisión',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _driverStatus == 'rejected' ? Colors.red.shade900 : Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _driverStatus == 'rejected'
                                  ? 'Actualiza tus datos para una nueva revisión'
                                  : 'Pronto podrás ofrecer viajes',
                              style: TextStyle(
                                fontSize: 12,
                                color: _driverStatus == 'rejected' ? Colors.red.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_driverStatus == 'rejected')
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.red),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterVehicleScreen(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

              // Resumen de reservas
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('solicitudes_viajes')
                    .where('passenger_id', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final solicitudes = snapshot.data!.docs;
                    final pendientes = solicitudes.where((s) => s['status'] == 'pendiente').length;
                    final aceptadas = solicitudes.where((s) => s['status'] == 'aceptada').length;
                    
                    if (pendientes > 0 || aceptadas > 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen de tus reservas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (pendientes > 0)
                                Expanded(
                                  child: Card(
                                    color: Colors.orange.withOpacity(0.1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$pendientes',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const Text(
                                            'Pendientes',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (pendientes > 0 && aceptadas > 0)
                                const SizedBox(width: 10),
                              if (aceptadas > 0)
                                Expanded(
                                  child: Card(
                                    color: Colors.green.withOpacity(0.1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$aceptadas',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const Text(
                                            'Confirmadas',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                  }
                  return const SizedBox();
                },
              ),
              
              // Buscador de viajes
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buscar viajes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: '¿A dónde quieres ir?',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        readOnly: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ActiveTripsScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ActiveTripsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Buscar Viajes Disponibles'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Opciones del estudiante
              const Text(
                'Opciones de Estudiante',
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
                    _StudentOptionCard(
                      title: 'Viajes Activos',
                      icon: Icons.directions_bus,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ActiveTripsScreen()),
                        );
                      },
                    ),
                    _StudentOptionCard(
                      title: 'Mis Reservas',
                      icon: Icons.event_seat,
                      color: Colors.orange,
                      onTap: () => _verMisReservas(context),
                    ),
                    _StudentOptionCard(
                      title: 'Historial',
                      icon: Icons.history,
                      color: Colors.purple,
                      onTap: () => _verHistorialEstudiante(context),
                    ),
                    _StudentOptionCard(
                      title: 'Perfil',
                      icon: Icons.person,
                      color: Colors.teal,
                      onTap: () {
                        // TODO: Implementar edición de perfil
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidad próximamente disponible'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
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

// Widget para las opciones del estudiante
class _StudentOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StudentOptionCard({
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