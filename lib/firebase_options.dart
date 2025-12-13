import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions no configurado para iOS. Configura si lo necesitas.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions no configurado para macOS. Configura si lo necesitas.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions no configurado para Windows. Configura si lo necesitas.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions no configurado para Linux. Configura si lo necesitas.',
        );
      default:
        throw UnsupportedError('Plataforma no soportada.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TU_API_KEY_WEB',
    appId: 'TU_APP_ID_WEB',
    messagingSenderId: 'TU_SENDER_ID_WEB',
    projectId: 'TU_PROJECT_ID',
    authDomain: 'TU_AUTH_DOMAIN_WEB',
    storageBucket: 'TU_STORAGE_BUCKET_WEB',
    measurementId: 'TU_MEASUREMENT_ID_WEB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFzMDfXa7E6U0h3MZ4c57g7PspOgmUjn8',
    appId: '1:980919011760:android:dafa9c5d49d9957ed8ee75',
    messagingSenderId: '980919011760',
    projectId: 'aplicativo-finu',
    storageBucket: 'aplicativo-finu.firebasestorage.app',
  );
}
