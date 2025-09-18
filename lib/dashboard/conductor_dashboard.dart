import 'package:flutter/material.dart';

class ConductorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Conductor')),
        body: const Center(
          child: Text(
            '¡Bienvenido Conductor!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
}