import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movuni/widgets/custom_textfield.dart';

class RegisterVehicleScreen extends StatefulWidget {
  const RegisterVehicleScreen({Key? key}) : super(key: key);

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _checkExistingVehicle();
  }

  Future<void> _checkExistingVehicle() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final vehicle = userData?['vehicle'] as Map<String, dynamic>?;
        
        if (vehicle != null) {
          // Si ya tiene vehículo registrado, cargar los datos para actualizar
          setState(() {
            _isUpdating = true;
            _licensePlateController.text = vehicle['licensePlate'] ?? '';
            _vehicleBrandController.text = vehicle['brand'] ?? '';
            _vehicleModelController.text = vehicle['model'] ?? '';
            _vehicleColorController.text = vehicle['color'] ?? '';
            _vehicleYearController.text = vehicle['year']?.toString() ?? '';
            _licenseNumberController.text = vehicle['licenseNumber'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar vehículo: $e');
    }
  }

  Future<void> _registerVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Preparar datos del vehículo
      Map<String, dynamic> vehicleData = {
        'licensePlate': _licensePlateController.text.trim().toUpperCase(),
        'brand': _vehicleBrandController.text.trim(),
        'model': _vehicleModelController.text.trim(),
        'color': _vehicleColorController.text.trim(),
        'year': int.parse(_vehicleYearController.text.trim()),
        'licenseNumber': _licenseNumberController.text.trim().toUpperCase(),
        'seats': 4,
        'verified': false,
        'verifiedAt': null,
        'verifiedBy': null,
      };

      // Actualizar documento del usuario
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'vehicle': vehicleData,
        'isDriver': true,
        'role': 'conductor',
        'driverStatus': 'pending_verification',
        'canOfferTrips': false,
        'totalTripsAsDriver': 0,
        'earnings': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // Mostrar diálogo de éxito
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                  SizedBox(width: 10),
                  Expanded(child: Text('¡Registro exitoso!')),
                ],
              ),
              content: Text(
                _isUpdating
                    ? 'Tu vehículo ha sido actualizado. Será verificado nuevamente por el administrador.'
                    : 'Tu vehículo ha sido registrado exitosamente. Un administrador verificará tu información pronto. '
                      'Debes cerrar sesión y volver a iniciar para ver los cambios.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // Cerrar sesión
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      // Redirigir al login
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar vehículo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdating ? 'Actualizar Vehículo' : 'Registrar Vehículo'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Encabezado
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.directions_car, color: Colors.white, size: 50),
                        SizedBox(height: 10),
                        Text(
                          'Conviértete en Conductor',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Registra tu vehículo y licencia de conducir',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Advertencia sobre licencia
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber.shade800, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Debes tener una licencia de conducir vigente y válida en Perú',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  // Título de sección
                  _buildSectionTitle('Datos del Vehículo'),
                  const SizedBox(height: 15),
                  
                  // Placa
                  CustomTextField(
                    controller: _licensePlateController,
                    labelText: 'Placa del vehículo',
                    hintText: 'Ej: ABC-123',
                    prefixIcon: Icons.pin,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(7),
                      UpperCaseTextFormatter(),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ingresa la placa';
                      if (value!.length < 6) return 'Placa inválida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // Marca y Modelo
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _vehicleBrandController,
                          labelText: 'Marca',
                          hintText: 'Ej: Toyota',
                          prefixIcon: Icons.branding_watermark,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Ingresa la marca';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _vehicleModelController,
                          labelText: 'Modelo',
                          hintText: 'Ej: Corolla',
                          prefixIcon: Icons.directions_car_outlined,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Ingresa el modelo';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // Color y Año
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _vehicleColorController,
                          labelText: 'Color',
                          hintText: 'Ej: Blanco',
                          prefixIcon: Icons.palette,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Ingresa el color';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _vehicleYearController,
                          labelText: 'Año',
                          hintText: '2020',
                          prefixIcon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Ingresa el año';
                            int? year = int.tryParse(value!);
                            if (year == null || year < 1990 || year > DateTime.now().year) {
                              return 'Año inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  // Título de sección
                  _buildSectionTitle('Licencia de Conducir'),
                  const SizedBox(height: 15),
                  
                  // Número de licencia
                  CustomTextField(
                    controller: _licenseNumberController,
                    labelText: 'Número de licencia',
                    hintText: 'Ej: Q12345678',
                    prefixIcon: Icons.credit_card,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      UpperCaseTextFormatter(),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ingresa tu número de licencia';
                      if (value!.length < 8) return 'Número de licencia inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  
                  // Información sobre verificación
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '¿Qué sucede después?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildInfoItem('1. Un administrador verificará tu vehículo y licencia'),
                        _buildInfoItem('2. Recibirás una notificación sobre el estado'),
                        _buildInfoItem('3. Una vez aprobado, podrás ofrecer viajes'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Botón de registro
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _registerVehicle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isUpdating ? 'Actualizar Vehículo' : 'Registrar Vehículo',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue[800],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.blue.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Formateador para convertir texto a mayúsculas
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}