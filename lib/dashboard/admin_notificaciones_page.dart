import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificacionesPage extends StatelessWidget {
  final notificacionesRef = FirebaseFirestore.instance.collection('notificaciones');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Notificaciones')),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificacionesRef.orderBy('fecha', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notificaciones = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notificaciones.length,
            itemBuilder: (context, index) {
              var n = notificaciones[index];
              bool leido = n['leido'] ?? false;

              return Card(
                color: leido ? Colors.grey[100] : Colors.purple[50],
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  leading: Icon(
                    leido ? Icons.notifications_none : Icons.notifications_active,
                    color: Colors.purple,
                  ),
                  title: Text(n['titulo']),
                  subtitle: Text(n['mensaje']),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'eliminar') {
                        await notificacionesRef.doc(n.id).delete();
                      } else if (value == 'leido') {
                        await notificacionesRef.doc(n.id).update({'leido': true});
                      } else if (value == 'no_leido') {
                        await notificacionesRef.doc(n.id).update({'leido': false});
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'leido', child: Text('Marcar como Leído')),
                      const PopupMenuItem(value: 'no_leido', child: Text('Marcar como No leído')),
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
