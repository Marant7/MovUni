import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movuni/utils/address_resolver.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({Key? key}) : super(key: key);

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  @override
  void initState() {
    super.initState();
  }

  Future<void> _marcarComoPagado(String solicitudId) async {
    try {
      await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .doc(solicitudId)
          .update({
        'pago_realizado': true,
        'fecha_pago': FieldValue.serverTimestamp(),
        'pago_confirmado_pasajero': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marcado como pagado. El conductor recibirá una notificación.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar como pagado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoPago(String solicitudId, Map<String, dynamic> solicitudData) {
    final metodosPago = List<dynamic>.from(solicitudData['metodosPago'] ?? []);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monto a pagar: S/ ${solicitudData['precio']}'),
                const SizedBox(height: 16),
                const Text(
                  'Métodos de pago disponibles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...metodosPago.map((metodo) {
                  if (metodo is Map<String, dynamic>) {
                    final tipo = metodo['tipo'] ?? '';
                    final numero = metodo['numero'];
                    
                    if (tipo == 'Efectivo') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.money, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Efectivo - Paga al conductor'),
                            ],
                          ),
                        ),
                      );
                    } else if (tipo == 'Yape' && numero != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.phone_android, color: Colors.purple, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Yape',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Número: $numero', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    } else if (tipo == 'Plin' && numero != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.phone_iphone, color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Plin',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Número: $numero', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                }).toList(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¿Ya realizaste el pago? Márcalo como pagado para que el conductor lo sepa.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _marcarComoPagado(solicitudId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Marcar como Pagado', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ⭐ MÉTODO CORREGIDO - AHORA DEVUELVE EL ASIENTO AL VIAJE
  Future<void> _cancelarReserva(String solicitudId, String motivo) async {
    try {
      // Obtener datos de la solicitud antes de cancelar
      final solicitudDoc = await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .doc(solicitudId)
          .get();
      
      if (!solicitudDoc.exists) return;
      final solicitudData = solicitudDoc.data()!;
      final tripId = solicitudData['trip_id'];
      final conductorId = solicitudData['conductor_id'];

      // Actualizar el estado de la solicitud a cancelado por pasajero
      await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .doc(solicitudId)
          .update({
        'status': 'cancelada_pasajero',
        'motivo_cancelacion': motivo,
        'fecha_cancelacion': FieldValue.serverTimestamp(),
      });

      // ⭐ DEVOLVER EL ASIENTO AL VIAJE (ESTO ES LO QUE FALTABA)
      final tripRef = FirebaseFirestore.instance.collection('viajes').doc(tripId);
      final tripSnapshot = await tripRef.get();
      
      if (tripSnapshot.exists) {
        final currentSeats = tripSnapshot.data()?['asientos'] ?? 0;
        await tripRef.update({
          'asientos': currentSeats + 1, // Incrementar asientos disponibles
        });
      }

      // Notificar al conductor
      await FirebaseFirestore.instance
          .collection('notificaciones')
          .add({
        'usuario_id': conductorId,
        'titulo': 'Reserva Cancelada',
        'mensaje': 'Un pasajero ha cancelado su reserva para el viaje ${solicitudData['origen']['nombre']} → ${solicitudData['destino']['nombre']}. Motivo: $motivo',
        'tipo': 'cancelacion_reserva',
        'solicitud_id': solicitudId,
        'trip_id': tripId,
        'leido': false,
        'fecha': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada correctamente. El asiento está nuevamente disponible.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar la reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoCancelacion(String solicitudId, Map<String, dynamic> solicitudData) {
    final TextEditingController motivoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Viaje: ${solicitudData['origen']['nombre']} → ${solicitudData['destino']['nombre']}'),
              const SizedBox(height: 8),
              Text('Fecha: ${solicitudData['fecha_viaje']} - ${solicitudData['hora']}'),
              const SizedBox(height: 16),
              const Text(
                'Motivo de cancelación:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Cambio de planes, emergencia, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta acción notificará al conductor sobre tu cancelación.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () {
                if (motivoController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _cancelarReserva(solicitudId, motivoController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa un motivo'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirmar Cancelación', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Reservas')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes_viajes')
            .where('passenger_id', isEqualTo: user!.uid)
            .orderBy('fecha_solicitud', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_seat_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes reservas',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Busca viajes disponibles para hacer tu primera reserva',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
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
              final reserva = reservas[index];
              final reservaData = reserva.data() as Map<String, dynamic>;
              final status = reservaData['status'] ?? 'pendiente';
              final pagoConfirmadoPasajero = reservaData['pago_confirmado_pasajero'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AddressPair(data: reservaData),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${reservaData['fecha_viaje']} - ${reservaData['hora']}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('S/ ${reservaData['precio']}'),
                        ],
                      ),
                      
                      // Mostrar estado de pago para reservas aceptadas
                      if (status == 'aceptada') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: pagoConfirmadoPasajero 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: pagoConfirmadoPasajero 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                pagoConfirmadoPasajero 
                                    ? Icons.check_circle 
                                    : Icons.pending_actions,
                                color: pagoConfirmadoPasajero 
                                    ? Colors.green 
                                    : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pagoConfirmadoPasajero 
                                      ? 'Pago confirmado ✓' 
                                      : 'Pago pendiente - Coordina con el conductor',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: pagoConfirmadoPasajero 
                                        ? Colors.green 
                                        : Colors.orange,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Mostrar información del conductor para reservas aceptadas
                      if (status == 'aceptada') ...[
                        const SizedBox(height: 8),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(reservaData['conductor_id'])
                              .get(),
                          builder: (context, conductorSnapshot) {
                            if (conductorSnapshot.hasData && conductorSnapshot.data!.exists) {
                              final conductorData = conductorSnapshot.data!.data() as Map<String, dynamic>;
                              final conductorName = '${conductorData['firstName'] ?? ''} ${conductorData['lastName'] ?? ''}'.trim();
                              final conductorPhone = conductorData['phone'] ?? '';
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Información del Conductor:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Nombre: $conductorName', style: const TextStyle(fontSize: 12)),
                                    if (conductorPhone.isNotEmpty)
                                      Text('Teléfono: $conductorPhone', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                      
                      // Mostrar información de cancelación
                      if (status.contains('cancelada')) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cancelado: ${reservaData['motivo_cancelacion'] ?? 'Sin motivo especificado'}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Mostrar métodos de pago para reservas aceptadas
                      if (status == 'aceptada' && reservaData['metodosPago'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Métodos de pago aceptados:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (reservaData['metodosPago'] as List).join(', '),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Botón para cancelar (solo para reservas pendientes o aceptadas)
                      if (status == 'pendiente' || status == 'aceptada') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Botón de pago solo para reservas aceptadas
                            if (status == 'aceptada' && !pagoConfirmadoPasajero)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _mostrarDialogoPago(reserva.id, reservaData),
                                  icon: const Icon(Icons.payment, size: 18),
                                  label: const Text('Confirmar Pago'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            if (status == 'aceptada' && !pagoConfirmadoPasajero)
                              const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _mostrarDialogoCancelacion(reserva.id, reservaData),
                                icon: const Icon(Icons.cancel, size: 18),
                                label: Text(status == 'pendiente' 
                                    ? 'Cancelar' 
                                    : 'Cancelar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'cancelada_conductor':
        return Colors.purple;
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
}