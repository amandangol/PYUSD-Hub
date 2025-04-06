// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC46bGOKnVIEMYgL6LpLmOxFGmLdWYFJuI',
    appId: '1:569602104504:web:b0887428d93e4b29e3284d',
    messagingSenderId: '569602104504',
    projectId: 'pyusd-flutter',
    authDomain: 'pyusd-flutter.firebaseapp.com',
    storageBucket: 'pyusd-flutter.firebasestorage.app',
    measurementId: 'G-XGK36BHQTV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8QhdSa-CWDr9qQ7l_ItH87ZkWyVGiIqw',
    appId: '1:569602104504:android:20b05ab93e391ba6e3284d',
    messagingSenderId: '569602104504',
    projectId: 'pyusd-flutter',
    storageBucket: 'pyusd-flutter.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDs8j_PTQChLq12U5aCHpSGjP0gnywtBuw',
    appId: '1:569602104504:ios:346ad1a8f6095193e3284d',
    messagingSenderId: '569602104504',
    projectId: 'pyusd-flutter',
    storageBucket: 'pyusd-flutter.firebasestorage.app',
    iosBundleId: 'com.example.pyusdForensics',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDs8j_PTQChLq12U5aCHpSGjP0gnywtBuw',
    appId: '1:569602104504:ios:346ad1a8f6095193e3284d',
    messagingSenderId: '569602104504',
    projectId: 'pyusd-flutter',
    storageBucket: 'pyusd-flutter.firebasestorage.app',
    iosBundleId: 'com.example.pyusdForensics',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC46bGOKnVIEMYgL6LpLmOxFGmLdWYFJuI',
    appId: '1:569602104504:web:388a6cefea8b6d2de3284d',
    messagingSenderId: '569602104504',
    projectId: 'pyusd-flutter',
    authDomain: 'pyusd-flutter.firebaseapp.com',
    storageBucket: 'pyusd-flutter.firebasestorage.app',
    measurementId: 'G-SZKPML3HSS',
  );
}
