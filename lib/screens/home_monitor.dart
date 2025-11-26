import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stress_detection_app/main.dart';
import 'package:stress_detection_app/core/theme.dart';
import 'package:stress_detection_app/core/camera_service.dart';
import 'package:stress_detection_app/core/stress_data.dart'; // IMPORTED BRIDGE
import 'package:stress_detection_app/widgets/camera_feed.dart';
import 'package:stress_detection_app/widgets/stat_card.dart';
import 'package:stress_detection_app/widgets/stress_graph.dart';

class HomeMonitorScreen extends StatefulWidget {
  const HomeMonitorScreen({super.key});

  @override
  State<HomeMonitorScreen> createState() => _HomeMonitorScreenState();
}

class _HomeMonitorScreenState extends State<HomeMonitorScreen> {
  Timer? _timer;
  String _sessionDuration = "00:00";
  File? _profileImage;

  // -- Graph Data --
  final List<FlSpot> _stressPoints = [];
  double _timeCounter = 0;

  // -- AI & Signal Processing --
  late FaceDetector _faceDetector;
  bool _isProcessing = false;
  CameraDescription? _frontCamera;

  // Precision Engine: Buffer to smooth out the "jitter"
  final List<double> _stressHistoryBuffer = [];
  final int _smoothingWindow = 5;

  // -- UI State --
  String _currentStatus = "Waiting...";
  Color _statusColor = Colors.grey;
  String _confidenceScore = "0%";

  // Track throttle time
  DateTime _lastProcessedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _initAI();
  }

  void _initAI() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    if (cameras.isNotEmpty) {
      _frontCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _startSessionTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final duration = DateTime.now().difference(sessionStartTime);
      final String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      if (mounted) setState(() => _sessionDuration = "$minutes:$seconds");
    });
  }

  // -- THE BRAIN: Precision & Stability Engine --
  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessing || _frontCamera == null) return;

    // RESPONSIVENESS FIX: Throttle to 500ms (2 FPS) to prevent OVERHEATING
    if (DateTime.now().difference(_lastProcessedTime).inMilliseconds < 500) return;

    _isProcessing = true;

    try {
      final inputImage = CameraService.inputImageFromCameraImage(image, _frontCamera!);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      double rawStressValue = _stressHistoryBuffer.isNotEmpty ? _stressHistoryBuffer.last : 100.0;
      String status = "Scanning...";
      Color color = Colors.grey;
      String confidence = "0%";

      if (faces.isNotEmpty) {
        final face = faces.first;
        double rawSmileProb = face.smilingProbability ?? 0.0;

        // SENSITIVITY BOOST (3x)
        double boostedSmile = rawSmileProb * 3.0;
        if (boostedSmile > 1.0) boostedSmile = 1.0;

        // Calculate Instantaneous Stress
        rawStressValue = (1.0 - boostedSmile) * 100;
        confidence = "${(rawSmileProb * 100).toInt()}% Detect";
      }

      // STABILITY ENGINE (Rolling Average)
      _stressHistoryBuffer.add(rawStressValue);
      if (_stressHistoryBuffer.length > _smoothingWindow) {
        _stressHistoryBuffer.removeAt(0);
      }

      // Calculate Stable Value
      double stableStress = _stressHistoryBuffer.reduce((a, b) => a + b) / _stressHistoryBuffer.length;

      // Determine UI Status
      if (stableStress < 20) {
        status = "Relaxed";
        color = AppTheme.statuscodecalm;
      } else if (stableStress < 80) {
        status = "Neutral";
        color = Colors.orange;
      } else {
        status = "High Stress";
        color = AppTheme.alertCoral;
      }

      if (mounted) {
        setState(() {
          _timeCounter += 0.5; // Slower X-Axis movement due to 500ms throttle
          _stressPoints.add(FlSpot(_timeCounter, stableStress));
          if (_stressPoints.length > 50) _stressPoints.removeAt(0);

          _currentStatus = status;
          _statusColor = color;
          _confidenceScore = confidence;

          // CRITICAL: Write to Bridge for Chat Bot Context
          StressData().update(stableStress, status);

          _lastProcessedTime = DateTime.now();
        });
      }

    } catch (e) {
      debugPrint("AI Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                  child: const Icon(Icons.grid_view, color: Colors.black87),
                ),
                Row(
                  children: [
                    const Icon(Icons.notifications_none, size: 28, color: Colors.black87),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            Text("Live Stress Monitor", style: AppTheme.titleStyle),
            const SizedBox(height: 24),
            CameraFeed(
              onFrame: _processCameraFrame,
              status: _currentStatus,
              statusColor: _statusColor,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                StatCard(label: "Analysis", value: _confidenceScore, icon: Icons.face),
                const SizedBox(width: 16),
                StatCard(label: "Session Time", value: _sessionDuration, icon: Icons.access_time),
              ],
            ),
            const SizedBox(height: 24),
            StressGraph(
              dataPoints: _stressPoints,
              maxX: _timeCounter,
              graphColor: _statusColor,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}