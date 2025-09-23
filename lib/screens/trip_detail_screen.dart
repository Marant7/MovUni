import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripDetailScreen extends StatelessWidget {
  final DocumentSnapshot trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

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
    final destino = trip['destino']['nombre'] ?? 'Sin destino';
    final origen = trip['origen']['nombre'] ?? 'Sin origen';
    final hora = trip['hora'] ?? '';
    final precio = trip['precio'] ?? 0;
    final asientos = trip['asientos'] ?? 0;
    final descripcion = trip['descripcion'] ?? 'Sin descripción';
    final metodosPago = List<String>.from(trip['metodosPago'] ?? []);
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
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$origen → $destino',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    const SizedBox(height: 16),
                    if (metodosPago.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Métodos de pago:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ...metodosPago.map((m) => Text('- $m')).toList(),
                        ],
                      ),
                    if (paradas.isNotEmpty) 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Paradas:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ...paradas.map((p) => Text('- ${p['nombre'] ?? 'Sin nombre'}')).toList(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _reservarViaje(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Reservar',
                  style: TextStyle(fontSize: 16),
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
