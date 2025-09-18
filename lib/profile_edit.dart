import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ProfileEditPage extends StatefulWidget {
  final String userType; // 'Admin', 'Estudiante', 'Conductor'
  const ProfileEditPage({Key? key, required this.userType}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  String? _errorMessage;

  bool _editMode = false; // Para alternar entre vista y edición

  // Carga los datos del usuario actual desde Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nombreController.text = data['nombres'] ?? '';
      _apellidosController.text = data['apellidos'] ?? '';
      _emailController.text = user.email ?? '';
      _telefonoController.text = data['telefono'] ?? '';
    } else {
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Diálogo para confirmar actualización
  void _confirmarActualizacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Está seguro que desea actualizar su perfil?', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() { _editMode = false; });
            },
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              Navigator.of(context).pop();
              _guardarPerfil();
            },
            child: const Text('Sí'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Guarda los datos editados en Firestore
  Future<void> _guardarPerfil() async {
    final nombres = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final telefono = _telefonoController.text.trim();

    // Validación
    if (nombres.isEmpty || apellidos.isEmpty || telefono.isEmpty) {
      setState(() { _errorMessage = 'Todos los campos son obligatorios.'; });
      return;
    }
    // Solo letras en nombres y apellidos (puedes ajustar el regex para admitir tildes y ñ)
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$").hasMatch(nombres)) {
      setState(() { _errorMessage = 'Nombres solo debe contener letras.'; });
      return;
    }
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$").hasMatch(apellidos)) {
      setState(() { _errorMessage = 'Apellidos solo debe contener letras.'; });
      return;
    }
    // Solo números y longitud 9 en teléfono
    if (!RegExp(r'^\d{9}$').hasMatch(telefono)) {
      setState(() { _errorMessage = 'El teléfono debe tener 9 dígitos y solo números.'; });
      return;
    }
    setState(() { _errorMessage = null; });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': user.email,
      'tipo': widget.userType,
    }, SetOptions(merge: true));

    // Mensaje de éxito
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Perfil actualizado correctamente', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() { _editMode = false; });
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Card de perfil (vista no editable)
  Widget _perfilView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.10), blurRadius: 8)],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.indigo.shade200,
                child: Text(
                  "${_nombreController.text.isNotEmpty ? _nombreController.text[0] : 'A'}${_apellidosController.text.isNotEmpty ? _apellidosController.text[0] : 'S'}",
                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${_nombreController.text} ${_apellidosController.text}",
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                "Universidad Privada de Tacna",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 2),
                  const Text('5 (0 reseñas)', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 7),
                  Chip(
                    label: const Text('Verificado', style: TextStyle(fontSize: 13, color: Colors.white)),
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                label: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                onPressed: () => setState(() { _editMode = true; }),
              ),
            ],
          ),
        ),
        // Información personal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información Personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Nombres',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: TextField(
                      controller: _apellidosController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Apellidos',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              TextField(
                controller: _emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              const Text('El correo institucional no se puede modificar', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 11),
              TextField(
                controller: _telefonoController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Card de edición del perfil
  Widget _perfilEdit() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.10), blurRadius: 8)],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.indigo.shade200,
                child: Text(
                  "${_nombreController.text.isNotEmpty ? _nombreController.text[0] : 'A'}${_apellidosController.text.isNotEmpty ? _apellidosController.text[0] : 'S'}",
                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${_nombreController.text} ${_apellidosController.text}",
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                "Universidad Privada de Tacna",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 2),
                  const Text('5 (0 reseñas)', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 7),
                  Chip(
                    label: const Text('Verificado', style: TextStyle(fontSize: 13, color: Colors.white)),
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información Personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ ]")), // Solo letras y espacios
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nombres',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: TextField(
                      controller: _apellidosController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ ]")), // Solo letras y espacios
                      ],
                      decoration: InputDecoration(
                        labelText: 'Apellidos',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              TextField(
                controller: _emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              const Text('El correo institucional no se puede modificar', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 11),
              TextField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                maxLength: 9,
                decoration: InputDecoration(
                  labelText: 'Teléfono (9 dígitos)',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      ),
                      icon: const Icon(Icons.save, size: 18, color: Colors.white),
                      label: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      onPressed: _confirmarActualizacion,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18, color: Colors.indigo),
                      label: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                      onPressed: () => setState(() { _editMode = false; }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FD),
      appBar: AppBar(
        title: Text('Perfil ${widget.userType}'),
        backgroundColor: Colors.indigo.shade900,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _editMode ? _perfilEdit() : _perfilView(),
        ),
      ),
    );
  }
}