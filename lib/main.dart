import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Constantes simples
const Color kPrimaryColor = Colors.blue;

// --- 1. Inicialización de Firebase ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa Firebase
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase Initialization Error: $e');
  }

  runApp(const SimpleAuthApp());
}

class SimpleAuthApp extends StatelessWidget {
  const SimpleAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Auth Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // AuthWrapper maneja si mostrar la pantalla de Login o Home.
      home: const AuthWrapper(),
    );
  }
}

// --- 2. WIDGET ENVOLTORIO DE AUTENTICACIÓN ---

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha los cambios en el estado de autenticación.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // Si hay usuario, muestra la pantalla de inicio (Home).
          return HomeScreen(user: user);
        }

        // Si no hay usuario, muestra la pantalla de inicio de sesión (Login).
        return const LoginScreen();
      },
    );
  }
}

// --- 3. PANTALLA DE INICIO DE SESIÓN (LOGIN) ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String _errorMessage = '';

  // Función para iniciar sesión con Google
  Future<void> signInWithGoogle() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // Usuario canceló
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sesión en Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de Auth: ${e.message}';
        });
      }
      print('Auth Error: $e');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
      print('General Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticación de Google (Simple)'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Inicia sesión para probar la autenticación.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // Botón de Google Sign-In
              ElevatedButton.icon(
                onPressed: _isLoading ? null : signInWithGoogle,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_Google_g_standard.png',
                        height: 24.0,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.login, color: kPrimaryColor),
                      ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 8.0,
                  ),
                  child: Text(
                    _isLoading ? 'Conectando...' : 'Iniciar Sesión con Google',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: kPrimaryColor, width: 1),
                  ),
                  elevation: 5,
                ),
              ),

              const SizedBox(height: 20),

              // Mostrar mensaje de error
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 4. PANTALLA DE INICIO (HOME) ---

class HomeScreen extends StatelessWidget {
  final User user;
  const HomeScreen({required this.user, super.key});

  // Función para cerrar la sesión
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName ?? 'Usuario';
    final email = user.email ?? 'Correo no disponible';

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, $displayName'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Sesión Iniciada Correctamente',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Divider(height: 30),

              _buildInfoRow(Icons.person, 'Nombre:', displayName),
              _buildInfoRow(Icons.email, 'Correo:', email),
              _buildInfoRow(Icons.fingerprint, 'UID:', user.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
