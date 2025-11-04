import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

/// Resuelve una dirección legible para un objeto de localización almacenado en Firestore.
/// `location` puede ser un Map con 'nombre' o con 'lat' y 'lng'.
Future<String> resolveAddressFromData(Map<String, dynamic>? location, String defaultName) async {
  if (location == null) return defaultName;

  // Si ya hay un nombre claro y no parece una coordenada, devolverlo
  final nombre = (location['nombre'] is String) ? (location['nombre'] as String).trim() : '';
  final coordPattern = RegExp(r'Lat:\s*-?\d+\.?\d+');
  if (nombre.isNotEmpty && !coordPattern.hasMatch(nombre)) {
    return nombre;
  }

  // Intentar leer lat/lng
  double? lat;
  double? lng;
  try {
    if (location['lat'] != null) lat = (location['lat'] as num).toDouble();
    if (location['lng'] != null) lng = (location['lng'] as num).toDouble();
  } catch (e) {
    // ignore
  }

  if (lat == null || lng == null) {
    // No hay coordenadas válidas; devolver nombre (podría estar vacío)
    return nombre.isNotEmpty ? nombre : defaultName;
  }

  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      // Construir dirección simple: street, subLocality, locality
      final parts = <String>[];
      if ((p.street ?? '').isNotEmpty) parts.add(p.street!);
      if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
      if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
      if ((p.administrativeArea ?? '').isNotEmpty) parts.add(p.administrativeArea!);
      if (parts.isNotEmpty) return parts.join(', ');
    }
  } catch (e) {
    // Fallthrough: si falla el geocoding, mostraremos coordenadas
  }

  // Fallback: mostrar coordenadas
  return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
}

/// Widget que muestra "origen → destino" resolviendo direcciones desde coordenadas
class AddressPair extends StatelessWidget {
  final Map<String, dynamic> data;
  final TextStyle? style;

  const AddressPair({required this.data, this.style, Key? key}) : super(key: key);

  Future<String> _resolveBoth() async {
    final origenText = await resolveAddressFromData(data['origen'] as Map<String, dynamic>?, 'Sin origen');
    final destinoText = await resolveAddressFromData(data['destino'] as Map<String, dynamic>?, 'Sin destino');
    return '$origenText → $destinoText';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolveBoth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 18,
            child: LinearProgressIndicator(minHeight: 4),
          );
        }
        final text = snapshot.data ?? 'Sin ubicación';
        return Text(
          text,
          style: style ?? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
