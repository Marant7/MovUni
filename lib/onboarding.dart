import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:flutter/services.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  Future<void> _onIntroEnd(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget circleIcon(IconData icon, Color colorBg, Color colorIcon) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorBg, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(2, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Icon(icon, size: 70, color: colorIcon),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Oculta barra de navegación y barra de estado
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,           // Esquina superior izquierda
            Color(0xFFB0BEC5),      // Plomo/Gris al centro (Cool Grey)
            Color(0xFF6A82FB),      // Azul esquina inferior derecha
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: IntroductionScreen(
        globalBackgroundColor: Colors.transparent,
        pages: [
          PageViewModel(
            titleWidget: Text(
              "Bienvenido a MovUni",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                shadows: [
                  Shadow(blurRadius: 8, color: Colors.blueGrey.shade200, offset: Offset(2,2)),
                ],
              ),
            ),
            bodyWidget: Text(
              "Gestiona tu movilidad estudiantil fácilmente.",
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueGrey.shade800,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            image: circleIcon(Icons.school, Colors.blue.shade100, Colors.blue.shade700),
          ),
          PageViewModel(
            titleWidget: Text(
              "Solicita tu movilidad",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700, // Gris plomo oscuro
                shadows: [
                  Shadow(blurRadius: 6, color: Colors.blueGrey.shade200, offset: Offset(2,2)),
                ],
              ),
            ),
            bodyWidget: Text(
              "Solicita traslados y revisa el estado desde tu app.",
              style: TextStyle(
                fontSize: 17,
                color: Colors.blueGrey.shade800, // Gris plomo medio
              ),
              textAlign: TextAlign.center,
            ),
            image: circleIcon(Icons.directions_bus, Color(0xFFB0BEC5), Colors.blue.shade700),
          ),
          PageViewModel(
            titleWidget: Text(
              "¡Comienza ahora!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                shadows: [
                  Shadow(blurRadius: 8, color: Colors.blueGrey.shade200, offset: Offset(2,2)),
                ],
              ),
            ),
            bodyWidget: Text(
              "Inicia sesión con tu correo institucional para comenzar.",
              style: TextStyle(
                fontSize: 17,
                color: Colors.blueGrey.shade800, // Gris plomo claro
              ),
              textAlign: TextAlign.center,
            ),
            image: circleIcon(Icons.login, Colors.blue.shade100, Colors.blue.shade700),
          ),
        ],
        onDone: () => _onIntroEnd(context),
        showSkipButton: true,
        skip: const Text('Saltar', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
        next: const Icon(Icons.arrow_forward, color: Color.fromARGB(255, 255, 255, 255)),
        done: const Text('Empezar', style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 255, 255))),
        dotsDecorator: DotsDecorator(
          size: const Size(10.0, 10.0),
          color: Color(0xFF78909C),          // Gris plomo para los dots
          activeSize: const Size(22.0, 10.0),
          activeColor: const Color.fromARGB(255, 255, 255, 255),    // Dot azul activo
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
      ),
    );
  }
}