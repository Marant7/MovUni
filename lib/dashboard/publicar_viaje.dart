import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../map_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/trip_status.dart'; // ✅ NUEVO IMPORT

// Coordenadas de la Universidad Privada de Tacna
final LatLng universidadTacna = LatLng(-18.0048523, -70.2261172);
LatLng? origenLatLng = universidadTacna;
LatLng? destinoLatLng;

class PublicarViajePage extends StatefulWidget {
  const PublicarViajePage({Key? key}) : super(key: key);

  @override
  State<PublicarViajePage> createState() => _PublicarViajePageState();
}

class _PublicarViajePageState extends State<PublicarViajePage> {
  final TextEditingController _origenController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _paradaController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _asientosController = TextEditingController(text: '1');
  final TextEditingController _precioController = TextEditingController(text: '5');
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _yapeController = TextEditingController();
  final TextEditingController _plinController = TextEditingController();
  String? _userPhone;

  List<Map<String, dynamic>> paradas = [];
  List<String> rutasPopulares = [
    'Universidad UPT → Centro de Tacna',
  ];

  Map<String, bool> metodosPago = {
    'Efectivo': true,
    'Yape': false,
    'Plin': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  // Carga el teléfono del usuario logueado desde la colección `users` en Firestore.
  Future<void> _loadUserPhone() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String? phoneFromDoc;
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['phone'] != null) {
          phoneFromDoc = data['phone'] as String?;
        }
      }
      setState(() {
        // Prioriza el número guardado en la colección users, si no existe usa phoneNumber de FirebaseAuth
        _userPhone = phoneFromDoc ?? FirebaseAuth.instance.currentUser?.phoneNumber;
        // Si alguno de los métodos ya está marcado, rellenar sus inputs si están vacíos
        if (metodosPago['Yape']! && _yapeController.text.trim().isEmpty) {
          _yapeController.text = _userPhone ?? '';
        }
        if (metodosPago['Plin']! && _plinController.text.trim().isEmpty) {
          _plinController.text = _userPhone ?? '';
        }
      });
    } catch (e) {
      // No bloquear la UI por este error; simplemente no auto-llenar si falla
    }
  }

  // ✅ FUNCIÓN ACTUALIZADA CON ESTADO
  Future<void> _guardarViaje() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showCenterMessage('Debes iniciar sesión primero');
        return;
      }

      // Validaciones de campos requeridos (paradas y descripción son opcionales)
      if (origenLatLng == null) {
        _showCenterMessage('Debes seleccionar el origen');
        return;
      }
      if (destinoLatLng == null) {
        _showCenterMessage('Debes seleccionar el destino');
        return;
      }
      if (_fechaController.text.trim().isEmpty) {
        _showCenterMessage('Debes seleccionar la fecha');
        return;
      }
      if (_horaController.text.trim().isEmpty) {
        _showCenterMessage('Debes seleccionar la hora de salida');
        return;
      }
      final int asientos = int.tryParse(_asientosController.text) ?? 0;
      if (asientos <= 0) {
        _showCenterMessage('El número de asientos debe ser mayor a 0');
        return;
      }
      final double precio = double.tryParse(_precioController.text) ?? 0.0;
      if (precio <= 0) {
        _showCenterMessage('El precio debe ser mayor a 0');
        return;
      }

      // Validar métodos de pago
      if (!metodosPago['Efectivo']! && !metodosPago['Yape']! && !metodosPago['Plin']!) {
        _showCenterMessage('Debes seleccionar al menos un método de pago');
        return;
      }

      // Validar números de Yape/Plin si están seleccionados
      final phoneYape = _yapeController.text.trim();
      final phonePlin = _plinController.text.trim();
      final validPhoneRegex = RegExp(r'^\d{9}$');
      if (metodosPago['Yape']!) {
        if (phoneYape.isEmpty) {
          _showCenterMessage('Debes ingresar tu número de Yape');
          return;
        }
        if (!validPhoneRegex.hasMatch(phoneYape)) {
          _showCenterMessage('Número de Yape inválido: debe tener 9 dígitos');
          return;
        }
      }
      if (metodosPago['Plin']!) {
        if (phonePlin.isEmpty) {
          _showCenterMessage('Debes ingresar tu número de Plin');
          return;
        }
        if (!validPhoneRegex.hasMatch(phonePlin)) {
          _showCenterMessage('Número de Plin inválido: debe tener 9 dígitos');
          return;
        }
      }

      // Construir lista de métodos de pago con números
      List<Map<String, dynamic>> metodosPagoList = [];
      if (metodosPago['Efectivo']!) {
        metodosPagoList.add({'tipo': 'Efectivo'});
      }
      if (metodosPago['Yape']!) {
        metodosPagoList.add({
          'tipo': 'Yape',
          'numero': _yapeController.text.trim(),
        });
      }
      if (metodosPago['Plin']!) {
        metodosPagoList.add({
          'tipo': 'Plin',
          'numero': _plinController.text.trim(),
        });
      }

      Map<String, dynamic> viaje = {
        "origen": {
          "nombre": _origenController.text,
          "lat": origenLatLng?.latitude,
          "lng": origenLatLng?.longitude,
        },
        "destino": {
          "nombre": _destinoController.text,
          "lat": destinoLatLng?.latitude,
          "lng": destinoLatLng?.longitude,
        },
        "paradas": paradas,
        "fecha": _fechaController.text,
        "hora": _horaController.text,
        "asientos": int.tryParse(_asientosController.text) ?? 1,
        "precio": double.tryParse(_precioController.text) ?? 5.0,
        "metodosPago": metodosPagoList,
        "descripcion": _descripcionController.text,
        "conductorId": user.uid,
        "estado": TripStatus.activo, // ✅ NUEVO: Estado inicial
        "timestamp": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('viajes').add(viaje);

      _showCenterMessage('¡Se publicó su viaje!', onClose: () {
        Navigator.of(context).pop();
      });
    } catch (e) {
      _showCenterMessage('Error: $e');
    }
  }

  // Mensaje centrado personalizado (usando Dialog)
  void _showCenterMessage(String mensaje, {VoidCallback? onClose}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onClose != null) onClose();
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Diálogo de confirmación antes de publicar
  void _confirmarPublicacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Seguro de publicar su viaje?', textAlign: TextAlign.center),
        content: const Text('¿Desea continuar con la publicación?', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              Navigator.of(context).pop();
              _guardarViaje();
            },
            child: const Text('Sí'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.indigo, size: 30),
            const SizedBox(width: 8),
            const Text('MovUni', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.10), blurRadius: 8)],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.directions_car, color: Colors.indigo, size: 22),
                  SizedBox(width: 8),
                  Text('Publicar Nuevo Viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Conecta con otros estudiantes universitarios', style: TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 18),
              const Text('Rutas populares (opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Column(
                children: rutasPopulares.map((ruta) => Padding(
                  padding: const EdgeInsets.only(bottom: 7.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.route_outlined, color: Colors.indigo),
                    label: Text(ruta, style: const TextStyle(color: Colors.black87)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      side: const BorderSide(color: Color(0xFFE3E7EE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: const Color(0xFFF6F8FC),
                    ),
                    onPressed: () {
                      List<String> partes = ruta.split('→');
                      setState(() {
                        _origenController.text = partes[0].trim();
                        _destinoController.text = partes.length > 1 ? partes[1].trim() : '';
                      });
                    },
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Origen *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              TextField(
                controller: _origenController,
                readOnly: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                  hintText: 'Universidad Privada de Tacna',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map, color: Colors.indigo),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapPickerPage(
                            initialLocation: universidadTacna,
                            title: 'Selecciona el origen',
                          ),
                        ),
                      );
                      if (result != null && result is LatLng) {
                        setState(() {
                          origenLatLng = result;
                          _origenController.text = 'Lat: ${result.latitude}, Lng: ${result.longitude}';
                        });
                      }
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Destino *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              TextField(
                controller: _destinoController,
                readOnly: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                  hintText: 'Selecciona destino',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map, color: Colors.indigo),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapPickerPage(
                            initialLocation: universidadTacna,
                            title: 'Selecciona el destino',
                          ),
                        ),
                      );
                      if (result != null && result is LatLng) {
                        setState(() {
                          destinoLatLng = result;
                          _destinoController.text = 'Lat: ${result.latitude}, Lng: ${result.longitude}';
                        });
                      }
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Paradas intermedias (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _paradaController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Selecciona parada',
                        filled: true,
                        fillColor: const Color(0xFFF6F8FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map, color: Colors.indigo),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapPickerPage(
                            initialLocation: universidadTacna,
                            title: 'Selecciona parada',
                          ),
                        ),
                      );
                      if (result != null && result is LatLng) {
                        setState(() {
                          _paradaController.text = 'Lat: ${result.latitude}, Lng: ${result.longitude}';
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.indigo),
                    onPressed: () {
                      if (_paradaController.text.trim().isNotEmpty) {
                        final texto = _paradaController.text.trim();
                        double? lat;
                        double? lng;
                        final latMatch = RegExp(r'Lat:\s*(-?\d+\.\d+)').firstMatch(texto);
                        final lngMatch = RegExp(r'Lng:\s*(-?\d+\.\d+)').firstMatch(texto);
                        if (latMatch != null) lat = double.tryParse(latMatch.group(1)!);
                        if (lngMatch != null) lng = double.tryParse(lngMatch.group(1)!);
                        setState(() {
                          paradas.add({
                            "nombre": texto,
                            "lat": lat,
                            "lng": lng,
                          });
                          _paradaController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              if (paradas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 7,
                    children: paradas.map((p) => Chip(
                      label: Text('${p["nombre"]}'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          paradas.remove(p);
                        });
                      },
                      backgroundColor: const Color(0xFFE3E7EE),
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Fecha *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              TextField(
                controller: _fechaController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today, color: Colors.indigo),
                  hintText: 'dd/mm/aaaa',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 2),
                  );
                  if (picked != null) {
                    _fechaController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Hora de salida *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              TextField(
                controller: _horaController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.access_time, color: Colors.indigo),
                  hintText: '--:--',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                readOnly: true,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    _horaController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Asientos disponibles *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              TextField(
                controller: _asientosController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.event_seat, color: Colors.indigo),
                  hintText: '1',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Precio por asiento *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              TextField(
                controller: _precioController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.indigo),
                  hintText: '5',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 3),
              const Text('Precio sugerido: S/ 5 - S/ 15', style: TextStyle(color: Colors.black45, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Métodos de pago que aceptas *', style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: [
                  CheckboxListTile(
                    value: metodosPago['Efectivo'],
                    onChanged: (val) {
                      setState(() {
                        metodosPago['Efectivo'] = val ?? false;
                      });
                    },
                    title: const Text('Efectivo'),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: Colors.indigo,
                  ),
                  CheckboxListTile(
                    value: metodosPago['Yape'],
                    onChanged: (val) {
                      setState(() {
                        metodosPago['Yape'] = val ?? false;
                        // Auto-fill con el teléfono del usuario si está seleccionado y el campo está vacío
                        if (metodosPago['Yape']! && _yapeController.text.trim().isEmpty) {
                          _yapeController.text = _userPhone ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                        }
                      });
                    },
                    title: const Text('Yape'),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: Colors.indigo,
                  ),
                  if (metodosPago['Yape']!)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 16, bottom: 8),
                      child: TextField(
                        controller: _yapeController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Número de Yape',
                          hintText: '999123456',
                          prefixIcon: const Icon(Icons.phone, color: Colors.purple),
                          filled: true,
                          fillColor: Colors.purple.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  CheckboxListTile(
                    value: metodosPago['Plin'],
                    onChanged: (val) {
                      setState(() {
                        metodosPago['Plin'] = val ?? false;
                        // Auto-fill con el teléfono del usuario si está seleccionado y el campo está vacío
                        if (metodosPago['Plin']! && _plinController.text.trim().isEmpty) {
                          _plinController.text = _userPhone ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
                        }
                      });
                    },
                    title: const Text('Plin'),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: Colors.indigo,
                  ),
                  if (metodosPago['Plin']!)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, right: 16, bottom: 8),
                      child: TextField(
                        controller: _plinController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Número de Plin',
                          hintText: '999123456',
                          prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.blue.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Descripción adicional (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 7),
              TextField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  hintText: 'Ej: Viaje cómodo y puntual, aire acondicionado, música...',
                  filled: true,
                  fillColor: const Color(0xFFF6F8FC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3E7EE)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.indigo, size: 19),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Importante:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 5),
                          Text('Al publicar un viaje te comprometes a:', style: TextStyle(fontSize: 13)),
                          SizedBox(height: 2),
                          Text('• Ser puntual y respetar los horarios establecidos\n'
                              '• Mantener comunicación con los pasajeros\n'
                              '• Conducir de manera segura y responsable\n'
                              '• Respetar los métodos de pago acordados',
                              style: TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _confirmarPublicacion,
                  child: const Text('Publicar Viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}