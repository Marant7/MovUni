import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
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
    Map<String, dynamic>? vehicleData,
  }) async {
    try {
      if (!email.endsWith('@virtual.upt.pe')) {
        throw Exception('Solo se permiten correos institucionales de la UPT');
      }

      // Validar que si es conductor, debe tener datos del vehículo
      if (isDriver && vehicleData == null) {
        throw Exception('Los conductores deben proporcionar datos del vehículo');
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.sendEmailVerification();

      // Preparar datos base del usuario
      Map<String, dynamic> userData = {
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
        'totalRatings': 0,
        'totalTrips': 0,
        'status': 'active',
      };

      // Si es conductor, agregar datos del vehículo
      if (isDriver && vehicleData != null) {
        userData['vehicle'] = {
          'licensePlate': vehicleData['licensePlate'],
          'brand': vehicleData['brand'],
          'model': vehicleData['model'],
          'color': vehicleData['color'],
          'year': vehicleData['year'],
          'licenseNumber': vehicleData['licenseNumber'],
          'seats': vehicleData['seats'] ?? 4,
          'verified': false, // Requiere verificación del administrador
          'verifiedAt': null,
          'verifiedBy': null,
        };
        
        // Estado adicional para conductores
        userData['driverStatus'] = 'pending_verification'; // pending_verification, verified, rejected
        userData['canOfferTrips'] = false; // Solo true cuando vehicle.verified = true
        userData['totalTripsAsDriver'] = 0;
        userData['earnings'] = 0.0;
      }

      // Guardar en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'El correo ya está registrado. Inicia sesión o recupera tu contraseña.',
        );
      } else if (e.code == 'weak-password') {
        throw Exception(
          'La contraseña es demasiado débil. Usa al menos 6 caracteres.',
        );
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
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // IMPORTANTE: Recargar el usuario para obtener el estado actualizado de emailVerified
      await userCredential.user!.reload();
      User? refreshedUser = _auth.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await _auth.signOut();
        throw Exception('Debes verificar tu correo antes de iniciar sesión.');
      }

      // Actualizar Firestore si el email fue verificado
      await _firestore.collection('users').doc(refreshedUser.uid).update({
        'emailVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return refreshedUser;
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

  /// Verificar vehículo de conductor (solo administrador)
  Future<void> verifyVehicle({
    required String userId,
    required bool approved,
    required String adminId,
    String? rejectionReason,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'vehicle.verified': approved,
        'vehicle.verifiedAt': FieldValue.serverTimestamp(),
        'vehicle.verifiedBy': adminId,
        'driverStatus': approved ? 'verified' : 'rejected',
        'canOfferTrips': approved,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!approved && rejectionReason != null) {
        updateData['vehicle.rejectionReason'] = rejectionReason;
      }

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('Error al verificar vehículo: $e');
    }
  }

  /// Actualizar datos del vehículo
  Future<void> updateVehicleData({
    required String userId,
    required Map<String, dynamic> vehicleData,
  }) async {
    try {
      // Al actualizar el vehículo, se debe volver a verificar
      vehicleData['verified'] = false;
      vehicleData['verifiedAt'] = null;
      vehicleData['verifiedBy'] = null;

      await _firestore.collection('users').doc(userId).update({
        'vehicle': vehicleData,
        'driverStatus': 'pending_verification',
        'canOfferTrips': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar vehículo: $e');
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

  /// Reenviar correo de verificación
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else if (user == null) {
        throw Exception('No hay usuario autenticado.');
      } else {
        throw Exception('El correo ya está verificado.');
      }
    } catch (e) {
      throw Exception('Error al reenviar correo de verificación: $e');
    }
  }

  /// Refrescar verificación de email y actualizar en Firestore
  Future<void> refreshEmailVerification(User user) async {
    await user.reload();
    User? refreshedUser = _auth.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      await _firestore.collection('users').doc(refreshedUser.uid).update({
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

  /// Verificar si un conductor puede ofrecer viajes
  Future<bool> canDriverOfferTrips(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['canOfferTrips'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Obtener conductores pendientes de verificación (para admin)
  Stream<QuerySnapshot> getPendingDriverVerifications() {
    return _firestore
        .collection('users')
        .where('isDriver', isEqualTo: true)
        .where('driverStatus', isEqualTo: 'pending_verification')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Obtener todos los conductores verificados
  Stream<QuerySnapshot> getVerifiedDrivers() {
    return _firestore
        .collection('users')
        .where('isDriver', isEqualTo: true)
        .where('driverStatus', isEqualTo: 'verified')
        .orderBy('rating', descending: true)
        .snapshots();
  }
}