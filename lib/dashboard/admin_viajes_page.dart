import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminViajesPage extends StatefulWidget {
  @override
  _AdminViajesPageState createState() => _AdminViajesPageState();
}

class _AdminViajesPageState extends State<AdminViajesPage> {
  final viajesRef = FirebaseFirestore.instance.collection('viajes');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Viajes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: viajesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final viajes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              var viaje = viajes[index];
              var origen = viaje['origen']['nombre'] ?? 'N/A';
              var destino = viaje['destino']['nombre'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: ListTile(
                  leading: const Icon(Icons.directions_car, color: Colors.blue),
                  title: Text('$origen → $destino'),
                  subtitle: Text('Hora: ${viaje['hora']} | Asientos: ${viaje['asientos']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'eliminar') {
                        await viajesRef.doc(viaje.id).delete();
                      } else if (value == 'editar') {
                        _editarViaje(viaje);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
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

  void _editarViaje(QueryDocumentSnapshot viaje) {
    final descripcionController = TextEditingController(text: viaje['descripcion']);
    final horaController = TextEditingController(text: viaje['hora']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Viaje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descripcionController, decoration: const InputDecoration(labelText: 'Descripción')),
            TextField(controller: horaController, decoration: const InputDecoration(labelText: 'Hora')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await viajesRef.doc(viaje.id).update({
                'descripcion': descripcionController.text,
                'hora': horaController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
