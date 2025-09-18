import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Importa esto para inputFormatters
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  List<String> paradas = [];
  List<String> rutasPopulares = [
    'Universidad UPT → Centro de Tacna',
  ];

  Map<String, bool> metodosPago = {
    'Efectivo': true,
    'Yape (999123456)': false,
    'Plin (999123456)': false,
  };

  void _agregarParada() {
    if (_paradaController.text.trim().isNotEmpty) {
      setState(() {
        paradas.add(_paradaController.text.trim());
        _paradaController.clear();
      });
    }
  }

  Future<void> _guardarViaje() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showCenterMessage('Debes iniciar sesión primero');
        return;
      }

      List<Map<String, dynamic>> paradasGuardadas = paradas.map((p) => {
        "nombre": p,
      }).toList();

      Map<String, dynamic> viaje = {
        "origen": {
          "nombre": _origenController.text,
        },
        "destino": {
          "nombre": _destinoController.text,
        },
        "paradas": paradasGuardadas,
        "fecha": _fechaController.text,
        "hora": _horaController.text,
        "asientos": int.tryParse(_asientosController.text) ?? 1,
        "precio": double.tryParse(_precioController.text) ?? 5.0,
        "metodosPago": metodosPago.entries.where((e)=>e.value).map((e)=>e.key).toList(),
        "descripcion": _descripcionController.text,
        "conductorId": user.uid,
        "timestamp": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('viajes').add(viaje);

      _showCenterMessage('¡Se publicó su viaje!', onClose: () {
        Navigator.of(context).pop(); // Regresa al inicio (ajusta según tu navegación)
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
            onPressed: () => Navigator.of(context).pop(), // NO: cerrar y seguir en formulario
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
              _guardarViaje(); // SÍ: Publica viaje
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                  hintText: 'Punto de partida',
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                  hintText: 'Punto de llegada',
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
                      decoration: InputDecoration(
                        hintText: 'Agregar parada',
                        filled: true,
                        fillColor: const Color(0xFFF6F8FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.indigo),
                    onPressed: _agregarParada,
                  ),
                ],
              ),
              if (paradas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 7,
                    children: paradas.map((p) => Chip(
                      label: Text(p),
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
                  FilteringTextInputFormatter.digitsOnly, // SOLO NÚMEROS
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
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // NÚMEROS Y UN PUNTO
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
                children: metodosPago.keys.map((metodo) => CheckboxListTile(
                  value: metodosPago[metodo],
                  onChanged: (val) {
                    setState(() {
                      metodosPago[metodo] = val ?? false;
                    });
                  },
                  title: Text(metodo),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  activeColor: Colors.indigo,
                )).toList(),
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
                  onPressed: _confirmarPublicacion, // <-- CAMBIA AQUÍ
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