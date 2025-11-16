import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movuni/services/auth_service.dart';
import 'package:movuni/widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Controladores para datos del vehículo
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _vehicleYearController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isDriver = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Preparar datos del vehículo si es conductor
        Map<String, dynamic>? vehicleData;
        if (_isDriver) {
          vehicleData = {
            'licensePlate': _licensePlateController.text.trim().toUpperCase(),
            'brand': _vehicleBrandController.text.trim(),
            'model': _vehicleModelController.text.trim(),
            'color': _vehicleColorController.text.trim(),
            'year': int.parse(_vehicleYearController.text.trim()),
            'licenseNumber': _licenseNumberController.text.trim(),
            'seats': 4, // Por defecto 4 asientos disponibles
            'verified': false, // Requiere verificación del admin
          };
        }
        
        await AuthService().signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dni: _dniController.text.trim(),
          phone: _phoneController.text.trim(),
          isDriver: _isDriver,
          role: _isDriver ? 'conductor' : 'estudiante',
          vehicleData: vehicleData,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isDriver 
                  ? '¡Registro exitoso! Verifica tu correo. Tu vehículo será revisado por el administrador.'
                  : '¡Registro exitoso! Verifica tu correo para poder iniciar sesión.'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
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
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    if (!value.endsWith('@virtual.upt.pe')) {
      return 'Solo se permiten correos con dominio @virtual.upt.pe';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta - MOVUNI'),
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
                  const Text(
                    'Únete a la comunidad MOVUNI',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Comparte viajes de forma segura con la comunidad UPT',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  
                  // DATOS PERSONALES
                  _buildSectionTitle('Datos Personales'),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _firstNameController,
                          labelText: 'Nombres',
                          prefixIcon: Icons.person,
                          validator: (value) => value?.isEmpty ?? true ? 'Ingresa tus nombres' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _lastNameController,
                          labelText: 'Apellidos',
                          prefixIcon: Icons.person_outline,
                          validator: (value) => value?.isEmpty ?? true ? 'Ingresa tus apellidos' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  CustomTextField(
                    controller: _dniController,
                    labelText: 'DNI',
                    prefixIcon: Icons.badge,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ingresa tu DNI';
                      if (value!.length != 8) return 'El DNI debe tener exactamente 8 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Teléfono',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ingresa tu teléfono';
                      if (value!.length != 9) return 'El teléfono debe tener exactamente 9 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Correo Institucional',
                    hintText: 'usuario@virtual.upt.pe',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 15),
                  
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ingresa una contraseña';
                      if (value!.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  
                  // SWITCH PARA CONDUCTOR
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isDriver ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDriver ? Colors.blue.shade300 : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: _isDriver ? Colors.blue.shade700 : Colors.grey.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrarme como conductor',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isDriver ? Colors.blue.shade900 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Podré ofrecer viajes y ganar dinero',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDriver,
                          onChanged: (value) => setState(() => _isDriver = value),
                          activeColor: Colors.blue[800],
                        ),
                      ],
                    ),
                  ),
                  
                  // FORMULARIO DE VEHÍCULO (aparece si es conductor)
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        const SizedBox(height: 25),
                        _buildSectionTitle('Datos del Vehículo'),
                        const SizedBox(height: 15),
                        
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.amber.shade800, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Debes tener licencia de conducir vigente para ser conductor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        
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
                            if (!_isDriver) return null;
                            if (value?.isEmpty ?? true) return 'Ingresa la placa';
                            if (value!.length < 6) return 'Placa inválida';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _vehicleBrandController,
                                labelText: 'Marca',
                                hintText: 'Ej: Toyota',
                                prefixIcon: Icons.branding_watermark,
                                validator: (value) {
                                  if (!_isDriver) return null;
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
                                  if (!_isDriver) return null;
                                  if (value?.isEmpty ?? true) return 'Ingresa el modelo';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _vehicleColorController,
                                labelText: 'Color',
                                hintText: 'Ej: Blanco',
                                prefixIcon: Icons.palette,
                                validator: (value) {
                                  if (!_isDriver) return null;
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
                                  if (!_isDriver) return null;
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
                        const SizedBox(height: 15),
                        
                        CustomTextField(
                          controller: _licenseNumberController,
                          labelText: 'Número de licencia de conducir',
                          hintText: 'Ej: Q12345678',
                          prefixIcon: Icons.credit_card,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(10),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (value) {
                            if (!_isDriver) return null;
                            if (value?.isEmpty ?? true) return 'Ingresa tu número de licencia';
                            if (value!.length < 8) return 'Número de licencia inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tu vehículo y licencia serán verificados por el administrador antes de poder ofrecer viajes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: _isDriver 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botón de registro
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isDriver ? 'Registrarse como Conductor' : 'Registrarse',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                  const SizedBox(height: 20),
                  
                  // Enlace para iniciar sesión
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: '¿Ya tienes cuenta? ',
                        style: const TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Inicia sesión',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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