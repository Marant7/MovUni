import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSolicitudesPage extends StatelessWidget {
  final solicitudesRef = FirebaseFirestore.instance.collection('solicitudes_viajes');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Solicitudes de Viaje')),
      body: StreamBuilder<QuerySnapshot>(
        stream: solicitudesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final solicitudes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              var s = solicitudes[index];
              var origen = s['origen']['nombre'] ?? 'N/A';
              var destino = s['destino']['nombre'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.orange),
                  title: Text('$origen → $destino'),
                  subtitle: Text('Estado: ${s['status']} | Fecha: ${s['fecha_viaje']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'eliminar') {
                        await solicitudesRef.doc(s.id).delete();
                      } else {
                        await solicitudesRef.doc(s.id).update({'status': value});
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'pendiente', child: Text('Marcar Pendiente')),
                      const PopupMenuItem(value: 'cancelada_pasajero', child: Text('Cancelada por Pasajero')),
                      const PopupMenuItem(value: 'completada', child: Text('Completada')),
                      const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
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
