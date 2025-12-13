import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  /// Registro con email y contraseña
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar datos adicionales en Firestore con timeout
      if (userCredential.user != null) {
        try {
          await _userService.saveUserData(
            uid: userCredential.user!.uid,
            firstName: firstName,
            lastName: lastName,
            email: email,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('WARNING: Firestore timeout - el usuario se registró en Auth pero los datos adicionales no se guardaron');
              throw Exception('Timeout al guardar datos en Firestore. Por favor verifica que Firestore esté habilitado en Firebase Console.');
            },
          );
        } catch (firestoreError) {
          print('ERROR Firestore: $firestoreError');
          // El usuario ya está registrado en Auth, solo advertimos sobre Firestore
          throw Exception('Usuario registrado pero error al guardar datos adicionales: $firestoreError');
        }
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Este correo ya está registrado');
        case 'invalid-email':
          throw Exception('El correo electrónico no es válido');
        case 'weak-password':
          throw Exception('La contraseña debe tener al menos 6 caracteres');
        default:
          throw Exception('Error al registrar usuario: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Inicio de sesión con email y contraseña
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No existe una cuenta con este correo');
        case 'wrong-password':
          throw Exception('Contraseña incorrecta');
        case 'invalid-email':
          throw Exception('El correo electrónico no es válido');
        case 'user-disabled':
          throw Exception('Esta cuenta ha sido deshabilitada');
        default:
          throw Exception('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Inicio de sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // Puedes manejar el error desde la UI leyendo null o lanzando una excepción personalizada.
      return null;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
