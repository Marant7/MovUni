import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialViajesPage extends StatelessWidget {
  const HistorialViajesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de Viajes')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Viajes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Como Conductor', icon: Icon(Icons.directions_car)),
              Tab(text: 'Como Pasajero', icon: Icon(Icons.person)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Viajes como conductor
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('viajes')
                  .where('conductorId', isEqualTo: user.uid)
                  .where('estado', isEqualTo: 'completado')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tienes viajes completados como conductor.'));
                }
                final viajes = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: viajes.length,
                  itemBuilder: (context, index) {
                    final viaje = viajes[index].data() as Map<String, dynamic>;
                    return _HistorialViajeCard(viaje: viaje, rol: 'conductor');
                  },
                );
              },
            ),
            // Tab 2: Viajes como pasajero
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('solicitudes_viajes')
                  .where('passenger_id', isEqualTo: user.uid)
                  .where('status', whereIn: ['aceptada', 'completada'])
                  .orderBy('fecha_viaje', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tienes viajes completados como pasajero.'));
                }
                final solicitudes = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final solicitud = solicitudes[index].data() as Map<String, dynamic>;
                    return _HistorialViajeCard(viaje: solicitud, rol: 'pasajero');
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _HistorialViajeCard extends StatelessWidget {
  final Map<String, dynamic> viaje;
  final String rol;
  const _HistorialViajeCard({required this.viaje, required this.rol});

  @override
  Widget build(BuildContext context) {
    final origen = viaje['origen']?['nombre'] ?? 'Sin origen';
    final destino = viaje['destino']?['nombre'] ?? 'Sin destino';
    final fecha = viaje['fecha_viaje'] ?? viaje['fecha'] ?? '';
    final hora = viaje['hora'] ?? '';
    final precio = viaje['precio'] ?? '';
    final asientos = viaje['asientos'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: rol == 'conductor'
            ? const Icon(Icons.directions_car, color: Colors.indigo)
            : const Icon(Icons.person, color: Colors.green),
        title: Text('$origen → $destino'),
        subtitle: Text(
          'Fecha: $fecha | Hora: $hora\n'
          'Asientos: $asientos | Precio: S/ $precio',
        ),
        trailing: Icon(Icons.star, color: Colors.amber), // Punto de entrada para calificación
        onTap: () {
          // Aquí puedes abrir pantalla de calificación o detalles
        },
      ),
    );
  }
}