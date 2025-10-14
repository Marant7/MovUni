import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  final FirebaseFirestore _firestore;

  RatingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Crear una calificación para un viaje completado
  Future<void> createRating({
    required String tripId,
    required String ratedUserId,
    required String raterUserId,
    required double rating,
    String? comment,
  }) async {
    try {
      // Validar que la calificación esté entre 1 y 5
      if (rating < 1 || rating > 5) {
        throw Exception('La calificación debe estar entre 1 y 5 estrellas');
      }

      // Verificar que el usuario no se califique a sí mismo
      if (ratedUserId == raterUserId) {
        throw Exception('No puedes calificarte a ti mismo');
      }

      // Verificar si ya existe una calificación de este usuario para este viaje
      final existingRating = await _firestore
          .collection('ratings')
          .where('tripId', isEqualTo: tripId)
          .where('raterUserId', isEqualTo: raterUserId)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .get();

      if (existingRating.docs.isNotEmpty) {
        throw Exception('Ya has calificado a este usuario en este viaje');
      }

      // Crear la calificación
      await _firestore.collection('ratings').add({
        'tripId': tripId,
        'ratedUserId': ratedUserId,
        'raterUserId': raterUserId,
        'rating': rating,
        'comment': comment ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Actualizar el promedio de calificación del usuario calificado
      await _updateUserRating(ratedUserId);
    } catch (e) {
      throw Exception('Error al crear calificación: $e');
    }
  }

  /// Actualizar el promedio de calificación de un usuario
  Future<void> _updateUserRating(String userId) async {
    try {
      // Obtener todas las calificaciones del usuario
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return;
      }

      // Calcular el promedio
      double totalRating = 0;
      int count = ratingsSnapshot.docs.length;

      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      double averageRating = totalRating / count;

      // Actualizar el perfil del usuario
      await _firestore.collection('users').doc(userId).update({
        'rating': averageRating,
        'totalRatings': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar calificación promedio: $e');
    }
  }

  /// Obtener todas las calificaciones de un usuario
  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> ratings = [];

      for (var doc in ratingsSnapshot.docs) {
        Map<String, dynamic> ratingData = doc.data();
        ratingData['id'] = doc.id;

        // Obtener información del usuario que calificó
        final raterDoc = await _firestore
            .collection('users')
            .doc(ratingData['raterUserId'])
            .get();

        if (raterDoc.exists) {
          ratingData['raterName'] =
              '${raterDoc.data()?['firstName']} ${raterDoc.data()?['lastName']}';
        }

        ratings.add(ratingData);
      }

      return ratings;
    } catch (e) {
      throw Exception('Error al obtener calificaciones: $e');
    }
  }

  /// Verificar si un usuario puede calificar a otro en un viaje específico
  Future<bool> canRateUser({
    required String tripId,
    required String raterUserId,
    required String ratedUserId,
  }) async {
    try {
      // Verificar si ya existe una calificación
      final existingRating = await _firestore
          .collection('ratings')
          .where('tripId', isEqualTo: tripId)
          .where('raterUserId', isEqualTo: raterUserId)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .get();

      return existingRating.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtener calificación promedio de un usuario
  Future<double> getUserAverageRating(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return (userDoc.data()?['rating'] as num?)?.toDouble() ?? 5.0;
      }

      return 5.0;
    } catch (e) {
      return 5.0;
    }
  }

  /// Obtener el total de calificaciones de un usuario
  Future<int> getUserTotalRatings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data()?['totalRatings'] ?? 0;
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Obtener calificaciones pendientes para un usuario
  Future<List<Map<String, dynamic>>> getPendingRatings(String userId) async {
    try {
      // Obtener viajes completados del usuario
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .get();

      List<Map<String, dynamic>> pendingRatings = [];

      for (var tripDoc in tripsSnapshot.docs) {
        Map<String, dynamic> tripData = tripDoc.data();
        String tripId = tripDoc.id;
        String driverId = tripData['driverId'];

        // Verificar si el usuario fue pasajero o conductor
        List<dynamic> passengers = tripData['passengers'] ?? [];
        bool isPassenger = passengers.any((p) => p['userId'] == userId);
        bool isDriver = driverId == userId;

        if (isPassenger || isDriver) {
          // Si es pasajero, puede calificar al conductor
          if (isPassenger) {
            bool canRate = await canRateUser(
              tripId: tripId,
              raterUserId: userId,
              ratedUserId: driverId,
            );

            if (canRate) {
              // Obtener datos del conductor
              final driverDoc = await _firestore
                  .collection('users')
                  .doc(driverId)
                  .get();

              pendingRatings.add({
                'tripId': tripId,
                'userToRateId': driverId,
                'userToRateName':
                    '${driverDoc.data()?['firstName']} ${driverDoc.data()?['lastName']}',
                'userToRateRole': 'Conductor',
                'tripData': tripData,
              });
            }
          }

          // Si es conductor, puede calificar a cada pasajero
          if (isDriver) {
            for (var passenger in passengers) {
              String passengerId = passenger['userId'];
              bool canRate = await canRateUser(
                tripId: tripId,
                raterUserId: userId,
                ratedUserId: passengerId,
              );

              if (canRate) {
                // Obtener datos del pasajero
                final passengerDoc = await _firestore
                    .collection('users')
                    .doc(passengerId)
                    .get();

                pendingRatings.add({
                  'tripId': tripId,
                  'userToRateId': passengerId,
                  'userToRateName':
                      '${passengerDoc.data()?['firstName']} ${passengerDoc.data()?['lastName']}',
                  'userToRateRole': 'Pasajero',
                  'tripData': tripData,
                });
              }
            }
          }
        }
      }

      return pendingRatings;
    } catch (e) {
      throw Exception('Error al obtener calificaciones pendientes: $e');
    }
  }
}
