import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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

  // Variables para la imagen de perfil
  File? _profileImageFile;
  String? _profileImageUrl;

  // Carga los datos del usuario actual desde Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        // Mapear a los campos existentes en la base de datos
        _nombreController.text = data['firstName'] ?? '';
        _apellidosController.text = data['lastName'] ?? '';
        _emailController.text = user.email ?? '';
        _telefonoController.text = data['phone'] ?? '';
        // Soportar distintas claves para la URL de la imagen si existen
        _profileImageUrl = data['profileImageUrl'] ?? data['photoURL'];
      });
    } else {
      setState(() {
        _emailController.text = user.email ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Diálogo para confirmar actualización (mejor diseño, fondo blanco y azul)
  void _confirmarActualizacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.indigo[700], size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirmar actualización',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                  fontSize: 19
                ),
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.indigo.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(8),
          child: Text(
            '¿Está seguro que desea actualizar su perfil?',
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton.icon(
            icon: Icon(Icons.close, color: Colors.red),
            label: Text('No', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() { _editMode = false; });
            },
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.check, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            label: Text('Sí', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(context).pop();
              await _guardarPerfil();
            },
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // Mensaje de éxito con diseño fondo blanco y azul
  void _mensajeExito(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.indigo.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[600], size: 48),
              SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Colors.indigo[900],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[700], fontSize: 16)),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() { _editMode = false; });
            },
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // Mensaje de error con diseño fondo blanco y azul
  void _mensajeError(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 48),
              SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700], fontSize: 16)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // Función para seleccionar/tomar imagen
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  // Función para subir la imagen a Firebase Storage y retornar la URL
  Future<String?> _uploadProfileImage(String uid) async {
    if (_profileImageFile == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(_profileImageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      _mensajeError('Error subiendo la imagen');
      return null;
    }
  }

  // Guarda los datos editados en Firestore (incluye la imagen)
  Future<void> _guardarPerfil() async {
    final nombres = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final telefono = _telefonoController.text.trim();

    // Validación
    if (nombres.isEmpty || apellidos.isEmpty || telefono.isEmpty) {
      _mensajeError('Todos los campos son obligatorios.');
      return;
    }
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$").hasMatch(nombres)) {
      _mensajeError('Nombres solo debe contener letras.');
      return;
    }
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$").hasMatch(apellidos)) {
      _mensajeError('Apellidos solo debe contener letras.');
      return;
    }
    if (!RegExp(r'^\d{9}$').hasMatch(telefono)) {
      _mensajeError('El teléfono debe tener 9 dígitos y solo números.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl;
    if (_profileImageFile != null) {
      imageUrl = await _uploadProfileImage(user.uid);
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      // Guardar en los mismos campos que ya existen en la base
      'firstName': nombres,
      'lastName': apellidos,
      'phone': telefono,
      'email': user.email,
      'tipo': widget.userType,
      if (imageUrl != null) 'profileImageUrl': imageUrl,
      // Marca de tiempo de última actualización
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Actualiza la URL local para mostrar la nueva imagen
    if (imageUrl != null) {
      setState(() {
        _profileImageUrl = imageUrl;
        _profileImageFile = null;
      });
    }
    _mensajeExito('¡Perfil actualizado correctamente!');
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
            boxShadow: [BoxShadow(
              color: Colors.indigo.shade100,
              blurRadius: 10,
              offset: Offset(0, 4)
            )],
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade100, Colors.indigo.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade200.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: (_profileImageUrl == null)
                      ? Text(
                          "${_nombreController.text.isNotEmpty ? _nombreController.text[0] : 'A'}${_apellidosController.text.isNotEmpty ? _apellidosController.text[0] : 'S'}",
                          style: const TextStyle(fontSize: 28, color: Colors.indigo, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "${_nombreController.text} ${_apellidosController.text}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 4),
              Text(
                "Universidad Privada de Tacna",
                style: TextStyle(fontSize: 16, color: Colors.indigo.shade400, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 22),
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
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  elevation: 4,
                  shadowColor: Colors.indigo.shade200,
                ),
                icon: const Icon(Icons.edit, size: 20, color: Colors.white),
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
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
              color: Colors.indigo.shade50,
              blurRadius: 12,
              offset: Offset(0, 6)
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información Personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Nombres',
                        filled: true,
                        fillColor: Colors.indigo.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.indigo.shade200),
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
                        fillColor: Colors.indigo.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.indigo.shade200),
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
                  fillColor: Colors.indigo.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.indigo.shade200),
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
                  fillColor: Colors.indigo.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.phone_android_outlined, color: Colors.indigo.shade200),
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
            boxShadow: [BoxShadow(
              color: Colors.indigo.shade200,
              blurRadius: 10,
              offset: Offset(0, 4)
            )],
          ),
          child: Column(
            children: [
              // Avatar con botones para escoger/tomar foto
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade100, Colors.indigo.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.shade200.withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(5),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImageFile != null
                              ? FileImage(_profileImageFile!)
                              : (_profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!) as ImageProvider
                                : null),
                          child: (_profileImageFile == null && _profileImageUrl == null)
                            ? Text(
                                "${_nombreController.text.isNotEmpty ? _nombreController.text[0] : 'A'}${_apellidosController.text.isNotEmpty ? _apellidosController.text[0] : 'S'}",
                                style: TextStyle(fontSize: 28, color: Colors.indigo, fontWeight: FontWeight.bold),
                              )
                            : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade900,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.shade200,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              )
                            ]
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.photo_camera, color: Colors.white, size: 21),
                                onPressed: () => _pickImage(ImageSource.camera),
                                tooltip: "Tomar foto",
                              ),
                              IconButton(
                                icon: Icon(Icons.photo_library, color: Colors.white, size: 21),
                                onPressed: () => _pickImage(ImageSource.gallery),
                                tooltip: "Elegir de galería",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
              Text(
                "${_nombreController.text} ${_apellidosController.text}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 4),
              Text(
                "Universidad Privada de Tacna",
                style: TextStyle(fontSize: 16, color: Colors.indigo.shade400, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 22),
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
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
              color: Colors.indigo.shade50,
              blurRadius: 12,
              offset: Offset(0, 6)
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Información Personal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ ]")),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nombres',
                        filled: true,
                        fillColor: Colors.indigo.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.indigo.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: TextField(
                      controller: _apellidosController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ ]")),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Apellidos',
                        filled: true,
                        fillColor: Colors.indigo.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.indigo.shade200),
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
                  fillColor: Colors.indigo.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.indigo.shade200),
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
                  fillColor: Colors.indigo.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.phone_android_outlined, color: Colors.indigo.shade200),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        elevation: 3,
                        shadowColor: Colors.indigo.shade200,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        side: BorderSide(color: Colors.indigo.shade200),
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
      backgroundColor: const Color(0xFFE7EBF6),
      appBar: AppBar(
        elevation: 1,
        title: Text('Perfil ${widget.userType}', style: TextStyle(letterSpacing: 0.5)),
        backgroundColor: Colors.indigo.shade900,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
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