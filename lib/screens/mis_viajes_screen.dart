import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisViajesScreen extends StatefulWidget {
  const MisViajesScreen({Key? key}) : super(key: key);

  @override
  State<MisViajesScreen> createState() => _MisViajesScreenState();
}

class _MisViajesScreenState extends State<MisViajesScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _cancelarViaje(String viajeId, String motivo) async {
    try {
      // Actualizar el estado del viaje a cancelado
      await FirebaseFirestore.instance
          .collection('viajes')
          .doc(viajeId)
          .update({
        'estado': 'cancelado',
        'motivo_cancelacion': motivo,
        'fecha_cancelacion': FieldValue.serverTimestamp(),
      });

      // Notificar a todos los pasajeros que solicitaron este viaje
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

        // Crear notificación para el pasajero
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
              Text('Viaje: ${viajeData['origen']['nombre']} → ${viajeData['destino']['nombre']}'),
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
              child: const Text('Cancelar'),
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
              final estado = viajeData['estado'] ?? 'activo';
              
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
                            child: Text(
                              '${viajeData['origen']['nombre']} → ${viajeData['destino']['nombre']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estado == 'activo' 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              estado == 'activo' ? 'ACTIVO' : 'CANCELADO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: estado == 'activo' ? Colors.green : Colors.red,
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
                      if (estado == 'cancelado') ...[
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
                      if (estado == 'activo') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  // Ver solicitudes del viaje
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
}

// Pantalla para ver solicitudes de un viaje específico
class SolicitudesViajeScreen extends StatelessWidget {
  final String viajeId;
  final Map<String, dynamic> viajeData;

  const SolicitudesViajeScreen({
    Key? key,
    required this.viajeId,
    required this.viajeData,
  }) : super(key: key);

  Future<void> _confirmarPago(
    BuildContext context,
    String solicitudId,
    String metodoPago,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('solicitudes_viajes')
          .doc(solicitudId)
          .update({
        'pago_confirmado_conductor': true,
        'metodo_pago_usado': metodoPago,
        'fecha_confirmacion_pago': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago confirmado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoConfirmarPago(
    BuildContext context,
    String solicitudId,
    Map<String, dynamic> solicitudData,
    String passengerName,
  ) {
    String? metodoPagoSeleccionado;
    final metodosPago = List<dynamic>.from(solicitudData['metodosPago'] ?? []);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.payment, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Confirmar Pago'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  passengerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monto: S/ ${solicitudData['precio']?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¿Con qué método pagó el pasajero?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...metodosPago.map((metodo) {
                      if (metodo is Map<String, dynamic>) {
                        final tipo = metodo['tipo'] ?? '';
                        final numero = metodo['numero'];
                        
                        return _buildMetodoPagoOption(
                          tipo,
                          numero,
                          metodoPagoSeleccionado,
                          (value) {
                            setState(() {
                              metodoPagoSeleccionado = value;
                            });
                          },
                        );
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
                              'Esta acción confirmará que recibiste el pago del pasajero.',
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
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: metodoPagoSeleccionado == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _confirmarPago(
                            dialogContext,
                            solicitudId,
                            metodoPagoSeleccionado!,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text('Confirmar Pago'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetodoPagoOption(
    String tipo,
    String? numero,
    String? seleccionado,
    Function(String?) onChanged,
  ) {
    Color color;
    IconData icon;
    String subtitle = '';

    switch (tipo) {
      case 'Efectivo':
        color = Colors.green;
        icon = Icons.money;
        subtitle = 'Pago en efectivo';
        break;
      case 'Yape':
        color = Colors.purple;
        icon = Icons.phone_android;
        subtitle = numero != null ? 'Número: $numero' : '';
        break;
      case 'Plin':
        color = Colors.blue;
        icon = Icons.phone_iphone;
        subtitle = numero != null ? 'Número: $numero' : '';
        break;
      default:
        color = Colors.grey;
        icon = Icons.payment;
        subtitle = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: seleccionado == tipo ? color : color.withOpacity(0.3),
          width: seleccionado == tipo ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: tipo,
        groupValue: seleccionado,
        onChanged: onChanged,
        activeColor: color,
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              tipo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
      ),
    );
  }

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
                    Text(
                      '${viajeData['origen']['nombre']} → ${viajeData['destino']['nombre']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    final solicitudData = solicitud.data() as Map<String, dynamic>;
                    final status = solicitudData['status'];
                    final passengerId = solicitudData['passenger_id'];
                    final pagoConfirmado = solicitudData['pago_confirmado_conductor'] ?? false;
                    final metodoPagoUsado = solicitudData['metodo_pago_usado'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(passengerId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String passengerName = 'Pasajero';
                        String passengerPhone = '';
                        
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          passengerName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                          passengerPhone = userData['phone'] ?? '';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status).withOpacity(0.2),
                              child: Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                              ),
                            ),
                            title: Text(
                              passengerName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getStatusText(status)),
                                if (passengerPhone.isNotEmpty)
                                  Text('Tel: $passengerPhone', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (pagoConfirmado)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (pagoConfirmado) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '✓ Pago Confirmado',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  if (metodoPagoUsado != null)
                                                    Text(
                                                      'Método: $metodoPagoUsado',
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (status == 'aceptada') ...[
                                      ElevatedButton.icon(
                                        onPressed: () => _mostrarDialogoConfirmarPago(
                                          context,
                                          solicitud.id,
                                          solicitudData,
                                          passengerName,
                                        ),
                                        icon: const Icon(Icons.payment),
                                        label: const Text('Confirmar Pago'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[700],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'No se puede confirmar pago para esta solicitud',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
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