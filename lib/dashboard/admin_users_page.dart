import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatefulWidget {
  @override
  _AdminUsersPageState createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('${user['firstName']} ${user['lastName']}'),
                  subtitle: Text('Email: ${user['email']} | Rol: ${user['role']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'activar' || value == 'desactivar') {
                        usersRef.doc(user.id).update({
                          'status': value == 'activar' ? 'active' : 'inactive'
                        });
                      } else if (value == 'eliminar') {
                        usersRef.doc(user.id).delete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'activar', child: Text('Activar')),
                      const PopupMenuItem(value: 'desactivar', child: Text('Desactivar')),
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
