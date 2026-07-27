import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDHFAxr9NE0Zw98WwIzbSlIMxqykkW6ztQ',
    appId: '1:624218788772:web:6710d70abcb53e2dcba731',
    messagingSenderId: '624218788772',
    projectId: 'salinha-criancas-app',
    authDomain: 'salinha-criancas-app.firebaseapp.com',
    storageBucket: 'salinha-criancas-app.firebasestorage.app',
  );
}
