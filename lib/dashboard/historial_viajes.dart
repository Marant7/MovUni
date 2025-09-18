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

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Viajes')),
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
            return const Center(child: Text('No tienes viajes publicados.'));
          }
          final viajes = snapshot.data!.docs;
          return ListView.builder(
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              final viaje = viajes[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${viaje['origen']['nombre']} → ${viaje['destino']['nombre']}'),
                  subtitle: Text(
                    'Fecha: ${viaje['fecha']} | Hora: ${viaje['hora']}\n'
                    'Asientos: ${viaje['asientos']} | Precio: S/ ${viaje['precio']}',
                  ),
                  trailing: const Icon(Icons.directions_car, color: Colors.indigo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}