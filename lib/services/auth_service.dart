import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Registro de usuario con validación de dominio institucional
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
      if (!email.endsWith('@virtual.upt.pe')) {
        throw Exception('Solo se permiten correos institucionales de la UPT');
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

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
        throw Exception(
            'El correo ya está registrado. Inicia sesión o recupera tu contraseña.');
      } else if (e.code == 'weak-password') {
        throw Exception(
            'La contraseña es demasiado débil. Use al menos 6 caracteres.');
      } else if (e.code == 'invalid-email') {
        throw Exception('El formato del correo electrónico no es válido.');
      } else {
        throw Exception('Error en el registro: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Inicio de sesión con validación de correo verificado
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Debes verificar tu correo antes de iniciar sesión.');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Usuario no encontrado.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta.');
      } else {
        throw Exception('Error en inicio de sesión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Enviar correo de recuperación de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación: $e');
    }
  }

  /// Refrescar verificación de email y actualizar en Firestore
  Future<void> refreshEmailVerification(User user) async {
    await user.reload();
    if (user.emailVerified) {
      await _firestore.collection('users').doc(user.uid).update({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Obtener datos del usuario desde Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}
