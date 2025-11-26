import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stress_detection_app/core/theme.dart';
import 'package:stress_detection_app/screens/main_shell.dart';

// -- GLOBAL VARIABLES --
// These are accessed by home_monitor.dart and camera_feed.dart
final DateTime sessionStartTime = DateTime.now();
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. LOAD SECRETS (API KEY)
  // This must happen before the app starts so the Chat screen can read it.
  try {
    await dotenv.load(fileName: "secret_key.env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
    // If .env is missing, the app will still launch, but Chat will fail safely.
  }

  // 2. UI OVERLAY CONFIGURATION
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // 3. INITIALIZE CAMERA HARDWARE
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
      title: 'Stress Detection',
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
      home: const MainShell(),
    );
  }
}