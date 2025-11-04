import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:movuni/screens/trip_detail_screen.dart';
import 'package:movuni/utils/address_resolver.dart';

class ActiveTripsScreen extends StatelessWidget {
  const ActiveTripsScreen({super.key});

  // Obtener fecha de hoy en formato dd/MM/yyyy usando hora local
  String getTodayDate() {
    final now = DateTime.now().toLocal();
    return DateFormat('dd/MM/yyyy').format(now);
  }

  // Stream que filtra los viajes donde el usuario YA tiene reserva
  Stream<List<DocumentSnapshot>> getAvailableTripsStream(String userId) async* {
    final today = getTodayDate();
    
    await for (var tripsSnapshot in FirebaseFirestore.instance
        .collection('viajes')
        .where('fecha', isEqualTo: today)
        .snapshots()) {
      
      List<DocumentSnapshot> availableTrips = [];
      
      for (var trip in tripsSnapshot.docs) {
        // Verificar si el usuario YA tiene una reserva en este viaje
        var reservaSnapshot = await FirebaseFirestore.instance
            .collection('solicitudes_viajes')
            .where('trip_id', isEqualTo: trip.id)
            .where('passenger_id', isEqualTo: userId)
            .where('status', whereIn: ['pendiente', 'aceptada'])
            .limit(1)
            .get();
        
        // Solo agregar el viaje si NO tiene reserva activa
        if (reservaSnapshot.docs.isEmpty) {
          availableTrips.add(trip);
        }
      }
      
      yield availableTrips;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Viajes Activos'),
          backgroundColor: Colors.green[700],
        ),
        body: const Center(
          child: Text('Debes iniciar sesión para ver los viajes'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viajes Activos'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: getAvailableTripsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar viajes: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay viajes disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ya tienes reservas en todos los viajes de hoy\no no hay viajes publicados',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final trips = snapshot.data!;
          
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final hora = trip['hora'] ?? '';
              final precio = trip['precio'] ?? 0;
              final asientos = trip['asientos'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: AddressPair(data: trip.data() as Map<String, dynamic>),
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