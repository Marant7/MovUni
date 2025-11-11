import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔔 Manejador de notificaciones en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Notificación en segundo plano: ${message.notification?.title}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // 🎯 Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    try {
      // 1. Solicitar permisos
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print("✅ Permisos de notificación: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Configurar notificaciones locales
        await _configureLocalNotifications();

        // 3. Obtener el token FCM
        String? token = await _messaging.getToken();
        print("🔑 FCM Token: $token");

        if (token != null) {
          await _saveTokenToFirestore(token);
        }

        // 4. Escuchar cambios del token
        _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

        // 5. Configurar manejadores de notificaciones
        _configureMessageHandlers();
      } else {
        print("⚠️ Permisos de notificación denegados");
      }
    } catch (e) {
      print("❌ Error al inicializar notificaciones: $e");
    }
  }

  // 💾 Guardar el token FCM en Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print("✅ Token FCM guardado en Firestore");
      }
    } catch (e) {
      print("❌ Error al guardar token: $e");
    }
  }

  // 🔧 Configurar notificaciones locales
  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'movuni_channel',
      'MovUni Notificaciones',
      description: 'Notificaciones de viajes y reservas',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 📱 Configurar manejadores de mensajes
  void _configureMessageHandlers() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Notificación en primer plano: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // Cuando el usuario toca la notificación con la app en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔔 Notificación tocada: ${message.data}");
      _handleNotificationTap(message.data);
    });

    // Manejador en segundo plano
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // 🔔 Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'movuni_channel',
            'MovUni Notificaciones',
            channelDescription: 'Notificaciones de viajes y reservas',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // 👆 Manejar cuando el usuario toca la notificación
  void _onNotificationTapped(NotificationResponse response) {
    print("🔔 Notificación tocada: ${response.payload}");
    // Aquí puedes navegar a una pantalla específica según el tipo de notificación
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print("🔔 Datos de la notificación: $data");
    // Aquí puedes navegar a una pantalla específica según el tipo de notificación
  }
}