// test/session_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movuni/services/session_service.dart';

void main() {
  late SessionService sessionService;

  setUp(() {
    sessionService = SessionService();
    SharedPreferences.setMockInitialValues({}); // Reinicia prefs en cada test
  });

  test('Debe guardar y obtener el rol del usuario', () async {
    await sessionService.saveUserRole('conductor');
    final role = await sessionService.getUserRole();
    expect(role, 'conductor');
  });

  test('Debe devolver null si no hay rol guardado', () async {
    final role = await sessionService.getUserRole();
    expect(role, isNull);
  });

  test('Debe eliminar el rol del usuario', () async {
    await sessionService.saveUserRole('pasajero');
    await sessionService.clearUserRole();
    final role = await sessionService.getUserRole();
    expect(role, isNull);
  });
}
