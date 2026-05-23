import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform for Firebase.');
    }
  }

  // Android config — from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAzQmvQ5Ye7c0YZlm7UYmbA5x7pbUj4BhU',
    appId: '1:171747195292:android:7cca0e8b7008608ce83059',
    messagingSenderId: '171747195292',
    projectId: 'aquaverse-375cb',
    storageBucket: 'aquaverse-375cb.firebasestorage.app',
  );

  // Web config — replace appId and apiKey after running: flutterfire configure
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBszWQjw9aIr4UVmsD--DQaw5aoLpErH0k',
    appId: '1:171747195292:web:4add370777502a65e83059',
    messagingSenderId: '171747195292',
    projectId: 'aquaverse-375cb',
    authDomain: 'aquaverse-375cb.firebaseapp.com',
    storageBucket: 'aquaverse-375cb.firebasestorage.app',
  );
}
