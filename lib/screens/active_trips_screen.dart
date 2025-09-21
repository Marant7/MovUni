import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:movuni/screens/trip_detail_screen.dart';

class ActiveTripsScreen extends StatelessWidget {
  const ActiveTripsScreen({super.key});

  // Obtener fecha de hoy en formato dd/MM/yyyy usando hora local
  String getTodayDate() {
    final now = DateTime.now().toLocal(); // forzar hora local
    return DateFormat('dd/MM/yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final today = getTodayDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes Activos'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('viajes')
            .where('fecha', isEqualTo: today) // comparar con la fecha de hoy
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay viajes activos hoy.'));
          }

          final trips = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final destino = trip['destino']['nombre'] ?? 'Sin destino';
              final origen = trip['origen']['nombre'] ?? 'Sin origen';
              final hora = trip['hora'] ?? '';
              final precio = trip['precio'] ?? 0;
              final asientos = trip['asientos'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text('$origen → $destino'),
                  subtitle: Text('Hora: $hora • Asientos: $asientos • Precio: S/$precio'),
                  leading: const Icon(Icons.directions_car, color: Colors.green),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailScreen(trip: trip),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
