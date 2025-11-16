import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard/admin_dashboard.dart';
import 'screens/register_screen.dart';
import 'screens/user_role_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');
  bool _isPasswordVisible = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  bool _isBlocked = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_isBlocked) {
      setState(() {
        _errorMessage = 'Demasiados intentos fallidos. Espera 10 segundos para volver a intentar.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Correo y contraseña son obligatorios.';
        _isLoading = false;
      });
      return;
    }

    // Validar dominio antes de intentar autenticar
    if (!email.endsWith('@virtual.upt.pe')) {
      setState(() {
        _errorMessage = 'Solo se permiten correos con dominio @virtual.upt.pe';
        _isLoading = false;
      });
      return;
    }

    try {
      // Autenticar con Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _failedAttempts = 0; // Reinicia el contador si el login es exitoso

      // Recargar el usuario para obtener el estado actualizado de emailVerified
      await userCredential.user!.reload();
      User? refreshedUser = FirebaseAuth.instance.currentUser;

      // Verificar si el correo está verificado en Firebase Auth
      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Debes verificar tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.';
          _isLoading = false;
        });
        return;
      }

      // Verificar si existe en Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Si el usuario no existe en Firestore, cerrar sesión y mostrar error
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'No existe una cuenta registrada con este correo. Por favor regístrate primero.';
          _isLoading = false;
        });
        return;
      }

      // Obtener datos del usuario de Firestore
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userRole = userData['role'] ?? 'estudiante';
      
      // Verificar el campo emailVerified en Firestore
      bool emailVerifiedInFirestore = userData['emailVerified'] ?? false;
      
      if (!emailVerifiedInFirestore) {
        // Actualizar el campo en Firestore si ya está verificado en Auth
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // VERIFICAR SI ESTÁ INACTIVO
      if (userData['status'] == 'inactive') {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Tu cuenta ha sido desactivada por el administrador.';
          _isLoading = false;
        });
        return;
      }

      // Verificar correos especiales para admin
      if (email == 'admin@virtual.upt.pe') {
        userRole = 'admin';
        // Actualizar el rol en Firestore si no es admin
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'role': 'admin'});
      }

      // Redirigir según el rol del usuario
      Widget destinationScreen;
      switch (userRole.toLowerCase()) {
        case 'admin':
          destinationScreen = AdminDashboard();
          break;
        case 'estudiante':
        case 'conductor':
          destinationScreen = UserRoleScreen();
          break;
        default:
          destinationScreen = UserRoleScreen();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destinationScreen),
        );
      }

    } on FirebaseAuthException catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        setState(() {
          _isBlocked = true;
          _errorMessage = 'Demasiados intentos fallidos. Espera 10 segundos para volver a intentar.';
          _isLoading = false;
        });
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _isBlocked = false;
              _failedAttempts = 0;
              _errorMessage = null;
            });
          }
        });
        return;
      }

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este correo. ¿Ya te registraste?';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del correo electrónico no es válido.';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada.';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos de inicio de sesión. Intenta más tarde.';
          break;
        case 'invalid-credential':
          errorMessage = 'Credenciales inválidas. Verifica tu correo y/o contraseña.';
          break;
        default:
          errorMessage = 'Correo o contraseña incorrectos. Por favor verifica tus datos.';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }
  
  void _mostrarDialogoRecuperarContrasena(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'Ingresa tu correo registrado',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingresa un correo')),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Correo de recuperación enviado a $email')),
                  );
                } on FirebaseAuthException catch (e) {
                  String mensaje = 'Error al enviar el correo';
                  if (e.code == 'user-not-found') {
                    mensaje = 'No existe una cuenta con ese correo.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mensaje)),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FD),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car,
                    size: 40,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accede con tu correo institucional',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Correo institucional',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    hintText: 'tu-email@virtual.upt.pe',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    hintText: '******',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _mostrarDialogoRecuperarContrasena(context);
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      '¿No tienes cuenta?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Regístrate aquí',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Solo puedes iniciar sesión con una cuenta previamente registrada',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        'Debes verificar tu correo antes de poder iniciar sesión',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}