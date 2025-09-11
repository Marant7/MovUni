import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dni,
    required String phone,
    required bool isDriver,
    required String role,
  }) async {
    try {
      // Validar dominio en el backend también (seguridad adicional)
      if (!email.endsWith('@virtual.upt.pe')) {
        throw Exception('Solo se permiten correos institucionales de la UPT');
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enviar email de verificación
      await userCredential.user!.sendEmailVerification();

      // Guardar información adicional en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'dni': dni,
        'phone': phone,
        'email': email,
        'isDriver': isDriver,
        'role': role,
        'university': 'Universidad Privada de Tacna',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rating': 5.0,
        'totalTrips': 0,
        'status': 'active',
      });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('El correo ya está registrado. Inicia sesión o recupera tu contraseña.');
      } else if (e.code == 'weak-password') {
        throw Exception('La contraseña es demasiado débil. Use al menos 6 caracteres.');
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del correo electrónico no es válido.');
      } else {
        throw Exception('Error en el registro: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // Otros métodos de autenticación (login, logout, etc.)
}