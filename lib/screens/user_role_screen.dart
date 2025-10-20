import 'package:flutter/material.dart';
import 'package:movuni/services/session_service.dart';
import 'package:movuni/dashboard/estudiante_dashboard.dart';
import 'package:movuni/dashboard/conductor_dashboard.dart';

class UserRoleScreen extends StatefulWidget {
  const UserRoleScreen({Key? key}) : super(key: key);

  @override
  State<UserRoleScreen> createState() => _UserRoleScreenState();
}

class _UserRoleScreenState extends State<UserRoleScreen> {
  final SessionService _sessionService = SessionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRole();
  }

  void _checkExistingRole() async {
    setState(() => _isLoading = true);
    
    final String? savedRole = await _sessionService.getUserRole();
    
    if (savedRole != null && mounted) {
      _redirectBasedOnRole(savedRole);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _selectRole(String role) async {
    setState(() => _isLoading = true);
    
    await _sessionService.saveUserRole(role);
    
    if (mounted) {
      _redirectBasedOnRole(role);
    }
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
                      description: 'Ofrece viajes y comparte tu vehículo con la comunidad UPT',
                      icon: Icons.directions_car,
                      color: Colors.blue[800]!,
                      onTap: () => _selectRole('conductor'),
                    ),
                    const SizedBox(height: 20),
                    
                    // Tarjeta de Pasajero
                    _RoleCard(
                      title: 'Pasajero',
                      description: 'Encuentra viajes y únete a otros conductores de la UPT',
                      icon: Icons.person,
                      color: Colors.green[700]!,
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

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
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
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}