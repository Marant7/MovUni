import 'package:flutter/material.dart';
import 'package:movuni/login.dart'; // ¡Importa tu archivo login.dart aquí!

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Quita el Scaffold y el Center con el Text('Hello World!')
      // y en su lugar, establece LoginPage como la pantalla de inicio.
      home: LoginPage(), // Aquí es donde llamas a tu LoginPage
    );
  }
}