import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsService {
  final FirebaseFirestore _firestore;

  ReportsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtener nuevos usuarios por período (día, semana o mes)
  Future<Map<String, dynamic>> getNewUsersByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String period = 'day', // 'day', 'week', 'month'
  }) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt')
          .get();

      Map<String, int> usersByPeriod = {};
      int totalUsers = usersSnapshot.docs.length;

      for (var doc in usersSnapshot.docs) {
        Timestamp? createdAt = doc.data()['createdAt'] as Timestamp?;
        if (createdAt != null) {
          DateTime date = createdAt.toDate();
          String periodKey = _getPeriodKey(date, period);
          usersByPeriod[periodKey] = (usersByPeriod[periodKey] ?? 0) + 1;
        }
      }

      return {
        'totalUsers': totalUsers,
        'usersByPeriod': usersByPeriod,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'period': period,
      };
    } catch (e) {
      throw Exception('Error al obtener nuevos usuarios: $e');
    }
  }

  /// Obtener viajes completados por período
  Future<Map<String, dynamic>> getCompletedTripsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String period = 'day', // 'day', 'week', 'month'
  }) async {
    try {
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThanOrEqualTo: startDate)
          .where('completedAt', isLessThanOrEqualTo: endDate)
          .orderBy('completedAt')
          .get();

      Map<String, int> tripsByPeriod = {};
      int totalTrips = tripsSnapshot.docs.length;
      int totalPassengers = 0;

      for (var doc in tripsSnapshot.docs) {
        Map<String, dynamic> tripData = doc.data();
        Timestamp? completedAt = tripData['completedAt'] as Timestamp?;

        if (completedAt != null) {
          DateTime date = completedAt.toDate();
          String periodKey = _getPeriodKey(date, period);
          tripsByPeriod[periodKey] = (tripsByPeriod[periodKey] ?? 0) + 1;

          // Contar pasajeros
          List<dynamic> passengers = tripData['passengers'] ?? [];
          totalPassengers += passengers.length;
        }
      }

      return {
        'totalTrips': totalTrips,
        'totalPassengers': totalPassengers,
        'tripsByPeriod': tripsByPeriod,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'period': period,
      };
    } catch (e) {
      throw Exception('Error al obtener viajes completados: $e');
    }
  }

  /// Obtener estadísticas generales del sistema
  Future<Map<String, dynamic>> getGeneralStatistics() async {
    try {
      // Total de usuarios
      final usersSnapshot = await _firestore.collection('users').get();
      int totalUsers = usersSnapshot.docs.length;

      // Usuarios por rol
      int conductores = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'conductor')
          .length;
      int pasajeros = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'pasajero')
          .length;
      int estudiantes = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'estudiante')
          .length;

      // Total de viajes
      final tripsSnapshot = await _firestore.collection('trips').get();
      int totalTrips = tripsSnapshot.docs.length;

      // Viajes por estado
      int completedTrips = tripsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;
      int activeTrips = tripsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      int cancelledTrips = tripsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'cancelled')
          .length;

      // Total de calificaciones
      final ratingsSnapshot = await _firestore.collection('ratings').get();
      int totalRatings = ratingsSnapshot.docs.length;

      // Promedio general de calificaciones
      double totalRatingSum = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRatingSum += (doc.data()['rating'] as num).toDouble();
      }
      double averageRating = totalRatings > 0
          ? totalRatingSum / totalRatings
          : 0.0;

      return {
        'totalUsers': totalUsers,
        'usersByRole': {
          'conductores': conductores,
          'pasajeros': pasajeros,
          'estudiantes': estudiantes,
        },
        'totalTrips': totalTrips,
        'tripsByStatus': {
          'completed': completedTrips,
          'active': activeTrips,
          'cancelled': cancelledTrips,
        },
        'totalRatings': totalRatings,
        'averageRating': averageRating.toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas generales: $e');
    }
  }

  /// Obtener usuarios más activos (por cantidad de viajes)
  Future<List<Map<String, dynamic>>> getTopActiveUsers({int limit = 10}) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('totalTrips', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> topUsers = [];

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data();
        topUsers.add({
          'userId': doc.id,
          'name': '${userData['firstName']} ${userData['lastName']}',
          'email': userData['email'],
          'role': userData['role'],
          'totalTrips': userData['totalTrips'] ?? 0,
          'rating': userData['rating'] ?? 5.0,
          'totalRatings': userData['totalRatings'] ?? 0,
        });
      }

      return topUsers;
    } catch (e) {
      throw Exception('Error al obtener usuarios más activos: $e');
    }
  }

  /// Obtener conductores mejor calificados
  Future<List<Map<String, dynamic>>> getTopRatedDrivers({
    int limit = 10,
  }) async {
    try {
      final driversSnapshot = await _firestore
          .collection('users')
          .where('isDriver', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> topDrivers = [];

      for (var doc in driversSnapshot.docs) {
        Map<String, dynamic> userData = doc.data();

        // Solo incluir si tiene al menos una calificación
        if ((userData['totalRatings'] ?? 0) > 0) {
          topDrivers.add({
            'userId': doc.id,
            'name': '${userData['firstName']} ${userData['lastName']}',
            'email': userData['email'],
            'totalTrips': userData['totalTrips'] ?? 0,
            'rating': userData['rating'] ?? 5.0,
            'totalRatings': userData['totalRatings'] ?? 0,
          });
        }
      }

      return topDrivers;
    } catch (e) {
      throw Exception('Error al obtener conductores mejor calificados: $e');
    }
  }

  /// Obtener tasa de crecimiento de usuarios
  Future<Map<String, dynamic>> getUserGrowthRate() async {
    try {
      DateTime now = DateTime.now();
      DateTime lastMonth = DateTime(now.year, now.month - 1, now.day);
      DateTime twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);

      // Usuarios del último mes
      final lastMonthUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: lastMonth)
          .where('createdAt', isLessThanOrEqualTo: now)
          .get();

      // Usuarios del mes anterior
      final previousMonthUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: twoMonthsAgo)
          .where('createdAt', isLessThanOrEqualTo: lastMonth)
          .get();

      int currentMonthCount = lastMonthUsers.docs.length;
      int previousMonthCount = previousMonthUsers.docs.length;

      double growthRate = 0.0;
      if (previousMonthCount > 0) {
        growthRate =
            ((currentMonthCount - previousMonthCount) / previousMonthCount) *
            100;
      }

      return {
        'currentMonthUsers': currentMonthCount,
        'previousMonthUsers': previousMonthCount,
        'growthRate': growthRate.toStringAsFixed(2),
        'growthRatePercentage': '${growthRate.toStringAsFixed(1)}%',
      };
    } catch (e) {
      throw Exception('Error al calcular tasa de crecimiento: $e');
    }
  }

  /// Obtener tasa de crecimiento de viajes
  Future<Map<String, dynamic>> getTripGrowthRate() async {
    try {
      DateTime now = DateTime.now();
      DateTime lastMonth = DateTime(now.year, now.month - 1, now.day);
      DateTime twoMonthsAgo = DateTime(now.year, now.month - 2, now.day);

      // Viajes del último mes
      final lastMonthTrips = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThanOrEqualTo: lastMonth)
          .where('completedAt', isLessThanOrEqualTo: now)
          .get();

      // Viajes del mes anterior
      final previousMonthTrips = await _firestore
          .collection('trips')
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThanOrEqualTo: twoMonthsAgo)
          .where('completedAt', isLessThanOrEqualTo: lastMonth)
          .get();

      int currentMonthCount = lastMonthTrips.docs.length;
      int previousMonthCount = previousMonthTrips.docs.length;

      double growthRate = 0.0;
      if (previousMonthCount > 0) {
        growthRate =
            ((currentMonthCount - previousMonthCount) / previousMonthCount) *
            100;
      }

      return {
        'currentMonthTrips': currentMonthCount,
        'previousMonthTrips': previousMonthCount,
        'growthRate': growthRate.toStringAsFixed(2),
        'growthRatePercentage': '${growthRate.toStringAsFixed(1)}%',
      };
    } catch (e) {
      throw Exception('Error al calcular tasa de crecimiento de viajes: $e');
    }
  }

  /// Obtener reporte completo para dashboard de administrador
  Future<Map<String, dynamic>> getCompleteAdminReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      DateTime start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      DateTime end = endDate ?? DateTime.now();

      final generalStats = await getGeneralStatistics();
      final newUsers = await getNewUsersByPeriod(
        startDate: start,
        endDate: end,
        period: 'week',
      );
      final completedTrips = await getCompletedTripsByPeriod(
        startDate: start,
        endDate: end,
        period: 'week',
      );
      final topUsers = await getTopActiveUsers(limit: 5);
      final topDrivers = await getTopRatedDrivers(limit: 5);
      final userGrowth = await getUserGrowthRate();
      final tripGrowth = await getTripGrowthRate();

      return {
        'generalStatistics': generalStats,
        'newUsers': newUsers,
        'completedTrips': completedTrips,
        'topActiveUsers': topUsers,
        'topRatedDrivers': topDrivers,
        'userGrowthRate': userGrowth,
        'tripGrowthRate': tripGrowth,
        'reportGeneratedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error al generar reporte completo: $e');
    }
  }

  /// Método auxiliar para obtener la clave del período
  String _getPeriodKey(DateTime date, String period) {
    switch (period) {
      case 'day':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'week':
        int weekOfYear = _getWeekOfYear(date);
        return '${date.year}-W${weekOfYear.toString().padLeft(2, '0')}';
      case 'month':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      default:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// Método auxiliar para obtener la semana del año
  int _getWeekOfYear(DateTime date) {
    int dayOfYear = int.parse(
      DateTime(
        date.year,
        date.month,
        date.day,
      ).difference(DateTime(date.year, 1, 1)).inDays.toString(),
    );
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Obtener datos para gráfico de tendencias (últimos N días/semanas/meses)
  Future<Map<String, dynamic>> getTrendData({
    required String dataType, // 'users' o 'trips'
    required String period, // 'day', 'week', 'month'
    int periodsBack = 12,
  }) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'day':
          startDate = endDate.subtract(Duration(days: periodsBack));
          break;
        case 'week':
          startDate = endDate.subtract(Duration(days: periodsBack * 7));
          break;
        case 'month':
          startDate = DateTime(
            endDate.year,
            endDate.month - periodsBack,
            endDate.day,
          );
          break;
        default:
          startDate = endDate.subtract(Duration(days: 30));
      }

      if (dataType == 'users') {
        return await getNewUsersByPeriod(
          startDate: startDate,
          endDate: endDate,
          period: period,
        );
      } else if (dataType == 'trips') {
        return await getCompletedTripsByPeriod(
          startDate: startDate,
          endDate: endDate,
          period: period,
        );
      } else {
        throw Exception('Tipo de dato no válido. Use "users" o "trips".');
      }
    } catch (e) {
      throw Exception('Error al obtener datos de tendencia: $e');
    }
  }
}
