import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:movuni/utils/address_resolver.dart';

// ============================================================
// HISTORIAL SOLO PARA CONDUCTORES
// ============================================================
class HistorialConductorPage extends StatelessWidget {
  const HistorialConductorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Conductor'),
          backgroundColor: Colors.blue[800],
        ),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        title: const Text('Historial de Conductor'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('viajes')
            .where('conductorId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes viajes en tu historial',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Los viajes que publiques aparecerán aquí',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final viajes = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              final viaje = viajes[index].data() as Map<String, dynamic>;
              final viajeId = viajes[index].id;
              return _HistorialConductorCard(
                viaje: viaje,
                viajeId: viajeId,
              );
            },
          );
        },
      ),
    );
  }
}

class _HistorialConductorCard extends StatelessWidget {
  final Map<String, dynamic> viaje;
  final String viajeId;

  const _HistorialConductorCard({
    required this.viaje,
    required this.viajeId,
  });

  @override
  Widget build(BuildContext context) {
  // Si el documento incluye nombre lo usaremos; si no, resolveremos por coordenadas abajo via AddressPair
    final fecha = viaje['fecha'] ?? '';
    final hora = viaje['hora'] ?? '';
    final precio = viaje['precio'] ?? 0;
    final asientos = viaje['asientos'] ?? 0;

    // Formatear fecha del timestamp
    String fechaFormateada = fecha;
    if (viaje['timestamp'] != null) {
      try {
        final timestamp = (viaje['timestamp'] as Timestamp).toDate();
        fechaFormateada = DateFormat('dd/MM/yyyy').format(timestamp);
      } catch (e) {
        // Si falla, usar la fecha string
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostrar direcciones resueltas (reverse-geocoding) o coordenadas como fallback
                      AddressPair(data: viaje),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$fechaFormateada - $hora',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.event_seat,
                  label: '$asientos asientos',
                  color: Colors.orange,
                ),
                _InfoChip(
                  icon: Icons.attach_money,
                  label: 'S/ $precio',
                  color: Colors.green,
                ),
                FutureBuilder<int>(
                  future: _contarPasajeros(viajeId),
                  builder: (context, snapshot) {
                    final pasajeros = snapshot.data ?? 0;
                    return _InfoChip(
                      icon: Icons.people,
                      label: '$pasajeros pasajeros',
                      color: Colors.blue,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _contarPasajeros(String viajeId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .where('viaje_id', isEqualTo: viajeId)
          .where('status', isEqualTo: 'aceptada')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

// ============================================================
// HISTORIAL SOLO PARA ESTUDIANTES (PASAJEROS)
// ============================================================
class HistorialEstudiantePage extends StatelessWidget {
  const HistorialEstudiantePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Viajes'),
          backgroundColor: Colors.green[700],
        ),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes_viajes')
            .where('passenger_id', isEqualTo: user.uid)
            .orderBy('fecha_solicitud', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes viajes en tu historial',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tus reservas y viajes realizados aparecerán aquí',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final reservas = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index].data() as Map<String, dynamic>;
              return _HistorialEstudianteCard(reserva: reserva);
            },
          );
        },
      ),
    );
  }
}

class _HistorialEstudianteCard extends StatelessWidget {
  final Map<String, dynamic> reserva;

  const _HistorialEstudianteCard({required this.reserva});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'cancelada_conductor':
      case 'cancelada_pasajero':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'aceptada':
        return 'ACEPTADA';
      case 'rechazada':
        return 'RECHAZADA';
      case 'cancelada_conductor':
        return 'CANCELADA';
      case 'cancelada_pasajero':
        return 'CANCELADA';
      default:
        return 'DESCONOCIDO';
    }
  }

  @override
  Widget build(BuildContext context) {
  // El nombre o las coordenadas serán mostradas por AddressPair (reverse-geocoding)
    final fecha = reserva['fecha_viaje'] ?? '';
    final hora = reserva['hora'] ?? '';
    final precio = reserva['precio'] ?? 0;
    final status = reserva['status'] ?? 'pendiente';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_seat,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mostrar direcciones resueltas (reverse-geocoding) o coordenadas como fallback
                      AddressPair(data: reserva),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$fecha - $hora',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 18, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'S/ $precio',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                if (status == 'aceptada' && reserva['pago_confirmado_pasajero'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Pagado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para chips de información
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// AddressPair and resolver moved to shared util `lib/utils/address_resolver.dart`