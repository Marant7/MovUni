import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      home: FirestoreTestWidget(),
    );
  }
}

class FirestoreTestWidget extends StatefulWidget {
  @override
  State<FirestoreTestWidget> createState() => _FirestoreTestWidgetState();
}

class _FirestoreTestWidgetState extends State<FirestoreTestWidget> {
  String result = 'Probando...';

  @override
  void initState() {
    super.initState();
    testFirestore();
  }

  Future<void> testFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('test').get();
      setState(() {
        result = 'Conexión OK. Documentos: ${snapshot.docs.length}';
      });
    } catch (e) {
      setState(() {
        result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(result)),
    );
  }
}