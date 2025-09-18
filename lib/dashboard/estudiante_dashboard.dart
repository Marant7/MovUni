import 'package:flutter/material.dart';

class EstudianteDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Estudiante')),
        body: const Center(
          child: Text(
            '¡Bienvenido Estudiante!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
}