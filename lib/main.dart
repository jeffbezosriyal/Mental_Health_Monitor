import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for signOut
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stress_detection_app/core/theme.dart';
import 'package:stress_detection_app/screens/auth_wrapper.dart';

// -- GLOBAL VARIABLES --
final DateTime sessionStartTime = DateTime.now();
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INITIALIZE FIREBASE
  try {
    await Firebase.initializeApp();

    // --- FORCE LOGOUT ON STARTUP ---
    // This kills the persistent session every time the app is killed and reopened.
    await FirebaseAuth.instance.signOut();

  } catch (e) {
    debugPrint("Firebase Initialization Failed: $e");
  }

  // 2. LOAD SECRETS (API KEY)
  try {
    await dotenv.load(fileName: "secret_key.env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  // 3. UI OVERLAY CONFIGURATION
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // 4. INITIALIZE CAMERA HARDWARE
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Camera Error: ${e.description}');
  }

  runApp(const StressApp());
}

class StressApp extends StatelessWidget {
  const StressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cortix',
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.backgroundIce,
        primaryColor: AppTheme.primaryTeal,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.textDark),
        ),
      ),
      // Ensure this points to AuthWrapper, which handles the routing
      home: const AuthWrapper(),
    );
  }
}