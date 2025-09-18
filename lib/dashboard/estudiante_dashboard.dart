import 'package:flutter/material.dart';
import '../profile_edit.dart';

class EstudianteDashboard extends StatelessWidget {
  const EstudianteDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Estudiante'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¡Bienvenido Estudiante!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditPage(userType: 'Estudiante'),
                    ),
                  );
                },
                child: const Text('Editar Perfil'),
              ),
            ],
          ),
        ),
      );
}