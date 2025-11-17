import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movuni/services/session_service.dart';
import 'package:movuni/dashboard/estudiante_dashboard.dart';
import 'package:movuni/dashboard/conductor_dashboard.dart';
import 'package:movuni/screens/register_vehicle_screen.dart';

class UserRoleScreen extends StatefulWidget {
  const UserRoleScreen({Key? key}) : super(key: key);

  @override
  State<UserRoleScreen> createState() => _UserRoleScreenState();
}

class _UserRoleScreenState extends State<UserRoleScreen> {
  final SessionService _sessionService = SessionService();
  bool _isLoading = true;
  bool _isDriver = false;
  bool _vehicleVerified = false;
  String _driverStatus = '';
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Si no hay usuario autenticado, redirigir al login
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Obtener datos del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      _userData = userDoc.data();
      _isDriver = _userData!['isDriver'] ?? false;
      _driverStatus = _userData!['driverStatus'] ?? '';

      // Verificar si hay un rol guardado previamente
      final String? savedRole = await _sessionService.getUserRole();
      
      if (savedRole != null && mounted) {
        _redirectBasedOnRole(savedRole);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectRole(String role) async {
    // Si intenta seleccionar conductor pero no es driver
    if (role == 'conductor' && !_isDriver) {
      _showRegisterVehicleDialog();
      return;
    }

    // Si es conductor, verificar que esté completamente verificado
    // Debe cumplir: vehicle.verified == true Y driverStatus == 'verified'
    if (role == 'conductor' && _isDriver) {
      bool isFullyVerified = _driverStatus == 'verified';
      
      if (!isFullyVerified) {
        _showVehicleNotVerifiedDialog();
        return;
      }
    }

    setState(() => _isLoading = true);
    await _sessionService.saveUserRole(role);
    
    if (mounted) {
      _redirectBasedOnRole(role);
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
              Text('Ofrece Viajes'),
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

    switch (_driverStatus) {
      case 'pending_verification':
        title = 'Verificación pendiente';
        message = 'Tu vehículo está en proceso de verificación por el administrador. '
                  'Te notificaremos cuando puedas comenzar a ofrecer viajes.';
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange;
        break;
      case 'rejected':
        title = 'Verificación rechazada';
        message = 'Tu solicitud fue rechazada. Por favor, actualiza los datos de tu vehículo '
                  'o contacta al administrador para más información.';
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            if (_driverStatus == 'rejected')
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
                child: const Text('Actualizar datos'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _redirectBasedOnRole(String role) {
    if (role == 'conductor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConductorDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EstudianteDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOVUNI - Elegir Rol'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Cómo quieres usar MOVUNI?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Selecciona tu rol para acceder a las funcionalidades correspondientes',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    
                    // Tarjeta de Conductor
                    _RoleCard(
                      title: 'Conductor',
                      description: _isDriver 
                          ? (_vehicleVerified && _driverStatus == 'verified'
                              ? 'Ofrece viajes y comparte tu vehículo con la comunidad UPT'
                              : 'Tu vehículo está en verificación')
                          : 'Regístrate como conductor para ofrecer viajes',
                      icon: Icons.directions_car,
                      color: Colors.blue[800]!,
                      isEnabled: true, // Siempre habilitado, pero con lógica diferente
                      showBadge: _isDriver && (!_vehicleVerified || _driverStatus != 'verified'),
                      badgeText: _driverStatus == 'pending_verification' 
                          ? 'Pendiente' 
                          : (_driverStatus == 'rejected' ? 'Rechazado' : ''),
                      onTap: () => _selectRole('conductor'),
                    ),
                    const SizedBox(height: 20),
                    
                    // Tarjeta de Pasajero
                    _RoleCard(
                      title: 'Pasajero',
                      description: 'Encuentra viajes y únete a otros conductores de la UPT',
                      icon: Icons.person,
                      color: Colors.green[700]!,
                      isEnabled: true,
                      onTap: () => _selectRole('pasajero'),
                    ),
                    const SizedBox(height: 30),
                    
                    // Información adicional
                    Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Puedes cambiar esta selección cerrando sesión y volviendo a ingresar',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
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

// Widget para las tarjetas de selección de rol
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool showBadge;
  final String badgeText;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
    this.showBadge = false,
    this.badgeText = '',
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                    if (showBadge && badgeText.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeText == 'Rechazado' ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios, 
                  color: isEnabled ? color : Colors.grey, 
                  size: 20
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}