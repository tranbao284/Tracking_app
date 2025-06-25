import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyC5_jqcFiypvHFr5mM43edwtgLsP0LgA8w",
        authDomain: "tracking-15c70.firebaseapp.com",
        projectId: "tracking-15c70",
        storageBucket: "tracking-15c70.firebasestorage.app",
        messagingSenderId: "991610307749",
        appId: "1:991610307749:web:2652ec7e8f541affa0f94c",
      );
    }
    throw UnsupportedError('This config is only for Web (Flutlab)');
  }
}
