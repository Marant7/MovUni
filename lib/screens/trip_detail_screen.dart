import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movuni/utils/address_resolver.dart';

class TripDetailScreen extends StatelessWidget {
  final DocumentSnapshot trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  void _mostrarDialogoConfirmacionReserva(BuildContext context) {
    final precio = trip['precio'] ?? 0;
    final metodosPago = List<dynamic>.from(trip['metodosPago'] ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirmar Reserva',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💰 Información de Pago',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precio: S/ ${precio.toStringAsFixed(2)}',
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
                'Métodos de pago aceptados por el conductor:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...metodosPago.map((metodo) {
                if (metodo is Map<String, dynamic>) {
                  final tipo = metodo['tipo'] ?? '';
                  final numero = metodo['numero'];
                  
                  if (tipo == 'Efectivo') {
                    return _buildMetodoPagoItem(
                      Icons.money,
                      'Efectivo',
                      'Paga al conductor en efectivo',
                      Colors.green,
                    );
                  } else if (tipo == 'Yape' && numero != null) {
                    return _buildMetodoPagoItem(
                      Icons.phone_android,
                      'Yape',
                      'Número: $numero',
                      Colors.purple,
                    );
                  } else if (tipo == 'Plin' && numero != null) {
                    return _buildMetodoPagoItem(
                      Icons.phone_iphone,
                      'Plin',
                      'Número: $numero',
                      Colors.blue,
                    );
                  }
                }
                return const SizedBox.shrink();
              }).toList(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El pago se realiza directamente con el conductor. Puedes usar cualquiera de los métodos mostrados arriba.',
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
            onPressed: () {
              Navigator.pop(context);
              _reservarViaje(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Reserva'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildMetodoPagoItem(IconData icon, String titulo, String subtitulo, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reservarViaje(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final tripRef = FirebaseFirestore.instance.collection('viajes').doc(trip.id);
    final tripSnapshot = await tripRef.get();
    final asientosDisponibles = tripSnapshot['asientos'] ?? 0;

    if (asientosDisponibles > 0) {
      try {
        // Crear la solicitud aceptada
        await FirebaseFirestore.instance.collection('solicitudes_viajes').add({
          'trip_id': trip.id,
          'passenger_id': user.uid,
          'conductor_id': trip['conductorId'],
          'status': 'aceptada',
          'fecha_solicitud': FieldValue.serverTimestamp(),
          'origen': trip['origen'],
          'destino': trip['destino'],
          'hora': trip['hora'],
          'fecha_viaje': trip['fecha'],
          'precio': trip['precio'],
          'descripcion': trip['descripcion'],
          'metodosPago': trip['metodosPago'],
          'paradas': trip['paradas'],
          'pago_realizado': false,
          'pago_confirmado_pasajero': false,
          'pago_confirmado_conductor': false,
        });

        // Actualizar asientos disponibles
        await tripRef.update({'asientos': asientosDisponibles - 1});

        // Notificar al conductor
        await FirebaseFirestore.instance.collection('notificaciones').add({
          'usuario_id': trip['conductorId'],
          'titulo': 'Nueva reserva',
          'mensaje': 'Un estudiante ha reservado un asiento en tu viaje.',
          'tipo': 'reserva_viaje',
          'viaje_id': trip.id,
          'leido': false,
          'fecha': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reserva confirmada! Tu lugar está asegurado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reservar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cupo disponible en este viaje.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  // origen/destino serán resueltos por AddressPair; no necesitamos extraerlos aquí
  final hora = trip['hora'] ?? '';
    final precio = trip['precio'] ?? 0;
    final asientos = trip['asientos'] ?? 0;
    final descripcion = trip['descripcion'] ?? 'Sin descripción';
    final metodosPago = List<dynamic>.from(trip['metodosPago'] ?? []);
    final paradas = List<Map<String, dynamic>>.from(trip['paradas'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Viaje'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mostrar direcciones resueltas (origen → destino)
                            AddressPair(data: trip.data() as Map<String, dynamic>),
                            const SizedBox(height: 16),
                            _buildDetailRow(Icons.access_time, 'Hora: $hora'),
                            _buildDetailRow(Icons.event, 'Fecha: ${trip['fecha']}'),
                            _buildDetailRow(Icons.people, 'Asientos disponibles: $asientos'),
                            _buildDetailRow(Icons.attach_money, 'Precio: S/ $precio'),
                            const SizedBox(height: 16),
                            const Text(
                              'Descripción:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(descripcion),
                            if (paradas.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Paradas:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              ...paradas.map((p) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: FutureBuilder<String>(
                                        future: resolveAddressFromData(p as Map<String, dynamic>?, p['nombre'] ?? 'Sin nombre'),
                                        builder: (context, snap) {
                                          if (snap.connectionState == ConnectionState.waiting) {
                                            return const Text('Cargando...');
                                          }
                                          return Text(snap.data ?? (p['nombre'] ?? 'Sin nombre'));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Card de métodos de pago
                    Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.payment, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Métodos de pago disponibles:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (metodosPago.isEmpty)
                              const Text('No se especificaron métodos de pago')
                            else
                              ...metodosPago.map((metodo) {
                                if (metodo is Map<String, dynamic>) {
                                  final tipo = metodo['tipo'] ?? '';
                                  final numero = metodo['numero'];
                                  
                                  if (tipo == 'Efectivo') {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.money, color: Colors.green, size: 24),
                                            SizedBox(width: 12),
                                            Text(
                                              'Efectivo',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else if (tipo == 'Yape' && numero != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone_android, color: Colors.purple, size: 24),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Yape',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.purple,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Número: $numero',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else if (tipo == 'Plin' && numero != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone_iphone, color: Colors.blue, size: 24),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Plin',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Número: $numero',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                } else if (metodo is String) {
                                  // Compatibilidad con formato antiguo
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                        const SizedBox(width: 8),
                                        Text(metodo),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }).toList(),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'El pago se coordina directamente con el conductor',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoConfirmacionReserva(context),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Reservar Asiento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
