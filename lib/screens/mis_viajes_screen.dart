import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/trip_status.dart';
import '../services/rating_service.dart';
import 'package:movuni/utils/address_resolver.dart';

class MisViajesScreen extends StatefulWidget {
  const MisViajesScreen({Key? key}) : super(key: key);

  @override
  State<MisViajesScreen> createState() => _MisViajesScreenState();
}

class _MisViajesScreenState extends State<MisViajesScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _comenzarViaje(String viajeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('viajes')
          .doc(viajeId)
          .update({
        'estado': TripStatus.enCurso,
        'fecha_inicio': FieldValue.serverTimestamp(),
      });

      final solicitudes = await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .where('trip_id', isEqualTo: viajeId)
          .where('status', isEqualTo: 'aceptada')
          .get();

      for (var solicitud in solicitudes.docs) {
        await FirebaseFirestore.instance
            .collection('notificaciones')
            .add({
          'usuario_id': solicitud['passenger_id'],
          'titulo': '¡El viaje ha comenzado!',
          'mensaje': 'Tu viaje ya está en curso. ¡Buen viaje!',
          'tipo': 'viaje_iniciado',
          'viaje_id': viajeId,
          'leido': false,
          'fecha': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Viaje iniciado! Buen viaje 🚗'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finalizarViaje(String viajeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('viajes')
          .doc(viajeId)
          .update({
        'estado': TripStatus.completado,
        'fecha_finalizacion': FieldValue.serverTimestamp(),
      });

      final solicitudes = await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .where('trip_id', isEqualTo: viajeId)
          .where('status', isEqualTo: 'aceptada')
          .get();

      for (var solicitud in solicitudes.docs) {
        await FirebaseFirestore.instance
            .collection('notificaciones')
            .add({
          'usuario_id': solicitud['passenger_id'],
          'titulo': 'Viaje completado',
          'mensaje': '¡Llegaste a tu destino! No olvides calificar al conductor.',
          'tipo': 'viaje_completado',
          'viaje_id': viajeId,
          'leido': false,
          'fecha': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje finalizado correctamente ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelarViaje(String viajeId, String motivo) async {
    try {
      await FirebaseFirestore.instance
          .collection('viajes')
          .doc(viajeId)
          .update({
        'estado': TripStatus.cancelado,
        'motivo_cancelacion': motivo,
        'fecha_cancelacion': FieldValue.serverTimestamp(),
      });

      final solicitudes = await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .where('trip_id', isEqualTo: viajeId)
          .where('status', whereIn: ['pendiente', 'aceptada'])
          .get();

      for (var solicitud in solicitudes.docs) {
        await solicitud.reference.update({
          'status': 'cancelada_conductor',
          'motivo_cancelacion': 'El conductor canceló el viaje: $motivo',
          'fecha_cancelacion': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('notificaciones')
            .add({
          'usuario_id': solicitud['passenger_id'],
          'titulo': 'Viaje Cancelado',
          'mensaje': 'El conductor ha cancelado el viaje. Motivo: $motivo',
          'tipo': 'cancelacion_viaje',
          'viaje_id': viajeId,
          'leido': false,
          'fecha': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje cancelado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar el viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoCancelacion(String viajeId, Map<String, dynamic> viajeData) {
    final TextEditingController motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Viaje'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Viaje: '),
                  const SizedBox(width: 6),
                  Expanded(child: AddressPair(data: viajeData)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Fecha: ${viajeData['fecha']} - ${viajeData['hora']}'),
              const SizedBox(height: 16),
              const Text(
                'Motivo de cancelación:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Problemas mecánicos, enfermedad, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta acción notificará a todos los pasajeros que solicitaron el viaje.',
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
                  _cancelarViaje(viajeId, motivoController.text.trim());
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
        appBar: AppBar(title: const Text('Mis Viajes')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Viajes'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('viajes')
            .where('conductorId', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
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
                  Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes viajes publicados',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
              final viaje = viajes[index];
              final viajeData = viaje.data() as Map<String, dynamic>;
              final estado = viajeData['estado'] ?? TripStatus.activo;

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
                            child: AddressPair(data: viajeData),
                          ),
                          _buildStatusBadge(estado),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${viajeData['fecha']} - ${viajeData['hora']}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${viajeData['asientos']} asientos'),
                          const SizedBox(width: 16),
                          const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('S/ ${viajeData['precio']}'),
                        ],
                      ),
                      if (viajeData['descripcion']?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(
                          viajeData['descripcion'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      if (estado == TripStatus.cancelado) ...[
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
                                  'Cancelado: ${viajeData['motivo_cancelacion'] ?? 'Sin motivo especificado'}',
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
                      
                      // BOTONES SEGÚN EL ESTADO
                      if (estado == TripStatus.activo) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SolicitudesViajeScreen(
                                        viajeId: viaje.id,
                                        viajeData: viajeData,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.people_outline),
                                label: const Text('Ver Solicitudes'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _comenzarViaje(viaje.id),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Comenzar Viaje'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _mostrarDialogoCancelacion(viaje.id, viajeData),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancelar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      if (estado == TripStatus.enCurso) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PasajerosViajeScreen(
                                        viajeId: viaje.id,
                                        viajeData: viajeData,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.people),
                                label: const Text('Ver Pasajeros'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _finalizarViaje(viaje.id),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Finalizar Viaje'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],

                      if (estado == TripStatus.completado) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Viaje completado exitosamente',
                                style: TextStyle(color: Colors.green, fontSize: 12),
                              ),
                            ],
                          ),
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

  Widget _buildStatusBadge(String estado) {
    Color color;
    String text;

    switch (estado) {
      case TripStatus.activo:
        color = Colors.green;
        text = 'ACTIVO';
        break;
      case TripStatus.enCurso:
        color = Colors.blue;
        text = 'EN CURSO';
        break;
      case TripStatus.completado:
        color = Colors.grey;
        text = 'COMPLETADO';
        break;
      case TripStatus.cancelado:
        color = Colors.red;
        text = 'CANCELADO';
        break;
      default:
        color = Colors.grey;
        text = 'DESCONOCIDO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ==========================================
// Pantalla de SOLICITUDES (estado: activo)
// ==========================================
class SolicitudesViajeScreen extends StatelessWidget {
  final String viajeId;
  final Map<String, dynamic> viajeData;

  const SolicitudesViajeScreen({
    Key? key,
    required this.viajeId,
    required this.viajeData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes del Viaje'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AddressPair(
                      data: viajeData,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${viajeData['fecha']} - ${viajeData['hora']}'),
                    Text('${viajeData['asientos']} asientos disponibles'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('solicitudes_viajes')
                  .where('trip_id', isEqualTo: viajeId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay solicitudes para este viaje'),
                  );
                }

                final solicitudes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final solicitud = solicitudes[index];
                    final status = solicitud['status'];
                    final passengerId = solicitud['passenger_id'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(passengerId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String passengerName = 'Pasajero';
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!;
                          passengerName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                              ),
                            ),
                            title: Text(passengerName),
                            subtitle: Text(_getStatusText(status)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pendiente':
        return Icons.schedule;
      case 'aceptada':
        return Icons.check_circle;
      case 'rechazada':
        return Icons.cancel;
      case 'cancelada_conductor':
        return Icons.cancel;
      case 'cancelada_pasajero':
        return Icons.person_off;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pendiente':
        return 'Esperando respuesta';
      case 'aceptada':
        return 'Solicitud aceptada';
      case 'rechazada':
        return 'Solicitud rechazada';
      case 'cancelada_conductor':
        return 'Cancelado por conductor';
      case 'cancelada_pasajero':
        return 'Cancelado por pasajero';
      default:
        return 'Estado desconocido';
    }
  }
}

// ==========================================
// Pantalla de PASAJEROS (estado: en_curso)
// ==========================================
class PasajerosViajeScreen extends StatefulWidget {
  final String viajeId;
  final Map<String, dynamic> viajeData;

  const PasajerosViajeScreen({
    Key? key,
    required this.viajeId,
    required this.viajeData,
  }) : super(key: key);

  @override
  State<PasajerosViajeScreen> createState() => _PasajerosViajeScreenState();
}

class _PasajerosViajeScreenState extends State<PasajerosViajeScreen> {
  final RatingService _ratingService = RatingService();

  Future<void> _confirmarPago(String solicitudId, String metodoPago) async {
    try {
      await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .doc(solicitudId)
          .update({
        'pago_confirmado_conductor': true,
        'metodo_pago_usado': metodoPago,
        'fecha_confirmacion_pago': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago confirmado correctamente ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoConfirmarPago(DocumentSnapshot solicitud) {
    String? metodoPagoSeleccionado;
    final metodosPago = List<Map<String, dynamic>>.from(widget.viajeData['metodosPago'] ?? []);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Confirmar Pago'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(solicitud['passenger_id'])
                        .get(),
                    builder: (context, userSnapshot) {
                      String passengerName = 'Pasajero';
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData = userSnapshot.data!;
                        passengerName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                      }
                      return Text(
                        'Pasajero: $passengerName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Monto: S/ ${widget.viajeData['precio']}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona el método de pago usado:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...metodosPago.map((metodo) {
                    final tipo = metodo['tipo'];
                    return RadioListTile<String>(
                      value: tipo,
                      groupValue: metodoPagoSeleccionado,
                      onChanged: (value) {
                        setStateDialog(() {
                          metodoPagoSeleccionado = value;
                        });
                      },
                      title: Text(tipo),
                      subtitle: tipo == 'Yape' || tipo == 'Plin'
                          ? Text('Número: ${metodo['numero']}')
                          : null,
                      dense: true,
                    );
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: metodoPagoSeleccionado != null
                      ? () {
                          Navigator.pop(dialogContext);
                          _confirmarPago(solicitud.id, metodoPagoSeleccionado!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoCalificar(DocumentSnapshot solicitud) async {
    double rating = 5.0;
    final TextEditingController comentarioController = TextEditingController();
    
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(solicitud['passenger_id'])
        .get();
    
    String passengerName = 'Pasajero';
    if (userSnapshot.exists) {
      final userData = userSnapshot.data()!;
      passengerName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Calificar Pasajero'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasajero: $passengerName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Calificación:'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text('Comentario (opcional):'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: comentarioController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario sobre el pasajero...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _ratingService.createRating(
                        tripId: widget.viajeId,
                        ratedUserId: solicitud['passenger_id'],
                        raterUserId: FirebaseAuth.instance.currentUser!.uid,
                        rating: rating,
                        comment: comentarioController.text.trim(),
                      );
                      
                      Navigator.pop(dialogContext);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calificación enviada correctamente ✓'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(dialogContext);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al calificar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enviar Calificación'),
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
      appBar: AppBar(
        title: const Text('Pasajeros del Viaje'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AddressPair(
                      data: widget.viajeData,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${widget.viajeData['fecha']} - ${widget.viajeData['hora']}'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_car, color: Colors.blue, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Viaje en curso',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('solicitudes_viajes')
                  .where('trip_id', isEqualTo: widget.viajeId)
                  .where('status', isEqualTo: 'aceptada')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay pasajeros en este viaje'),
                  );
                }

                final pasajeros = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pasajeros.length,
                  itemBuilder: (context, index) {
                    final solicitud = pasajeros[index];
                    final passengerId = solicitud['passenger_id'];
                    final pagoConfirmado = solicitud['pago_confirmado_conductor'] ?? false;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(passengerId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String passengerName = 'Pasajero';
                        String passengerPhone = '';
                        
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!;
                          passengerName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                          passengerPhone = userData['phone'] ?? '';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: pagoConfirmado 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              child: Icon(
                                pagoConfirmado ? Icons.check_circle : Icons.person,
                                color: pagoConfirmado ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              passengerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (passengerPhone.isNotEmpty)
                                  Text('Tel: $passengerPhone'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      pagoConfirmado ? Icons.check_circle : Icons.pending,
                                      size: 14,
                                      color: pagoConfirmado ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pagoConfirmado ? 'Pago confirmado' : 'Pago pendiente',
                                      style: TextStyle(
                                        color: pagoConfirmado ? Colors.green : Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (!pagoConfirmado) ...[
                                      ElevatedButton.icon(
                                        onPressed: () => _mostrarDialogoConfirmarPago(solicitud),
                                        icon: const Icon(Icons.attach_money),
                                        label: const Text('Confirmar Pago'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (pagoConfirmado) ...[
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Pagó con: ${solicitud['metodo_pago_usado'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    FutureBuilder<bool>(
                                      future: _ratingService.canRateUser(
                                        tripId: widget.viajeId,
                                        raterUserId: FirebaseAuth.instance.currentUser!.uid,
                                        ratedUserId: passengerId,
                                      ),
                                      builder: (context, canRateSnapshot) {
                                        final canRate = canRateSnapshot.data ?? true;
                                        
                                        if (!canRate) {
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.star, color: Colors.blue, size: 16),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Ya calificaste a este pasajero',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        
                                        return OutlinedButton.icon(
                                          onPressed: () => _mostrarDialogoCalificar(solicitud),
                                          icon: const Icon(Icons.star_outline),
                                          label: const Text('Calificar Pasajero'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.amber[700],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}