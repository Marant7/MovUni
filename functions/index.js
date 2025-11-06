const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

// 🔔 Cloud Function que se activa cuando se crea una notificación
exports.enviarNotificacionPush = onDocumentCreated(
    "notificaciones/{notifId}",
    async (event) => {
      const notifData = event.data.data();

      console.log("Nueva notificación creada:", notifData);

      // Obtener el usuario que recibirá la notificación
      const usuarioId = notifData.usuario_id;

      if (!usuarioId) {
        console.error("No se encontró usuario_id en la notificación");
        return null;
      }

      try {
        // Obtener el token FCM del usuario desde Firestore
        const db = getFirestore();
        const userDoc = await db.collection("users").doc(usuarioId).get();

        if (!userDoc.exists) {
          console.error("Usuario no encontrado:", usuarioId);
          return null;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          console.error("Usuario no tiene token FCM:", usuarioId);
          return null;
        }

        // Construir el mensaje de notificación
        const message = {
          notification: {
            title: notifData.titulo || "MovUni",
            body: notifData.mensaje || "Tienes una nueva notificación",
          },
          data: {
            tipo: notifData.tipo || "general",
            notificacion_id: event.params.notifId,
            viaje_id: notifData.viaje_id || "",
            solicitud_id: notifData.solicitud_id || "",
            trip_id: notifData.trip_id || "",
          },
          token: fcmToken,
        };

        // Enviar la notificación push
        const messaging = getMessaging();
        const response = await messaging.send(message);
        console.log("Notificación enviada exitosamente:", response);

        return response;
      } catch (error) {
        console.error("Error al enviar notificación:", error);
        return null;
      }
    }
);