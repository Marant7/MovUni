# MovUni 🚗🎓

**Sistema de carpooling universitario para la Universidad Privada de Tacna**

## 📋 Descripción

MovUni es una aplicación móvil desarrollada en Flutter que conecta estudiantes universitarios para compartir viajes de manera segura, económica y eficiente.

## ✨ Características Principales

### 🔐 Autenticación Segura
- Registro con correo institucional (@virtual.upt.pe)
- Verificación de email obligatoria
- Recuperación de contraseña
- Sistema de roles dinámico

### 👥 Sistema de Roles

#### 🎓 Estudiante (Pasajero)
- Buscar viajes activos del día
- Ver detalles completos de viajes
- Solicitar reservas
- **Ver historial de TODAS mis reservas** (pendientes, aceptadas, rechazadas, canceladas)
- Cancelar reservas con motivo
- Confirmar pagos realizados

#### 🚗 Conductor
- Publicar viajes con origen/destino
- Configurar precio y asientos disponibles
- Agregar paradas intermedias
- Definir métodos de pago (Efectivo, Yape, Plin)
- Aceptar/rechazar solicitudes de pasajeros
- **Ver historial de TODOS mis viajes publicados**
- Recibir notificaciones de pagos

### 💰 Sistema de Pagos
- **Efectivo**: Pago directo al conductor
- **Yape**: Con número de teléfono
- **Plin**: Con número de teléfono
- Confirmación de pago por parte del pasajero

### 🗺️ Integración de Mapas
- Google Maps para seleccionar ubicaciones
- Universidad UPT como punto de referencia
- Coordenadas guardadas para cada ubicación

## 🔄 Cambios Recientes (04/11/2025)

### ✅ Historial Independiente por Rol

**Problema resuelto**: Anteriormente el historial mostraba AMBOS roles (conductor y pasajero) en pestañas, causando confusión.

**Solución implementada**:

1. **`HistorialConductorPage`** - Historial exclusivo para conductores
   - Muestra SOLO los viajes que el usuario ha publicado como conductor
   - Incluye contador de pasajeros por viaje
   - Información de asientos, precio y fecha
   - Diseño en azul (color del rol conductor)

2. **`HistorialEstudiantePage`** - Historial exclusivo para estudiantes
   - Muestra SOLO las reservas que el usuario ha hecho como pasajero
   - Estados visuales: pendiente, aceptada, rechazada, cancelada
   - Indicador de pago confirmado
   - Diseño en verde (color del rol estudiante)

3. **Dashboards actualizados**:
   - Dashboard de Conductor → llama a `HistorialConductorPage`
   - Dashboard de Estudiante → llama a `HistorialEstudiantePage`
   - Cada usuario ve SOLO el historial relevante a su rol activo

**Beneficios**:
- ✅ **Cero confusión**: Cada rol ve solo su historial correspondiente
- ✅ **Mejor UX**: Información clara y específica
- ✅ **Separación de responsabilidades**: Código más mantenible

## 📱 Tecnologías Utilizadas

- **Flutter** - Framework de desarrollo
- **Firebase Auth** - Autenticación
- **Cloud Firestore** - Base de datos en tiempo real
- **Google Maps** - Mapas y geolocalización
- **Shared Preferences** - Almacenamiento local

## 🗄️ Estructura de Firebase

### Colecciones:
- `users` - Información de usuarios
- `viajes` - Viajes publicados por conductores
- `solicitudes_viajes` - Reservas de estudiantes
- `notificaciones` - Sistema de notificaciones

## 🚀 Instalación

```bash
# Clonar el repositorio
git clone https://github.com/Marant7/MovUni.git

# Instalar dependencias
cd MovUni
flutter pub get

# Ejecutar la aplicación
flutter run
```

## 📄 Licencia

Este proyecto es parte del desarrollo académico de la Universidad Privada de Tacna.

---

**Desarrollado con ❤️ para la comunidad universitaria UPT**
