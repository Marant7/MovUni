import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movuni/screens/register_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIRA BRO - UPT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: const RegisterScreen(), // Puedes cambiar esto por tu pantalla de inicio
      debugShowCheckedModeBanner: false,
    );
  }
}