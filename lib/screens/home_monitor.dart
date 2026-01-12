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
import 'package:stress_detection_app/core/stress_data.dart';
import 'package:stress_detection_app/widgets/camera_feed.dart';
import 'package:stress_detection_app/widgets/stat_card.dart';
import 'package:stress_detection_app/widgets/stress_graph.dart';

import '../core/calibration_service.dart';

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
  final int _smoothingWindow = 8;

  // -- UI State --
  String _currentStatus = "Waiting...";
  Color _statusColor = Colors.grey;
  String _confidenceScore = "0%";

  // Track throttle time
  DateTime _lastProcessedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    CalibrationService().loadBaselines(); // Load saved user data
    _startSessionTimer();
    _initAI();
  }

  void _initAI() {
    // OPTIMIZATION: Ensure performanceMode is FAST.
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
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
      // SYNC: Update the global singleton
      StressData().updateProfileImage(File(pickedFile.path));
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

  // ------------------------------------------------------------------------
  // THE CONTEXT-AWARE ENGINE (OPTIMIZED)
  // ------------------------------------------------------------------------
  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessing || _frontCamera == null) return;

    // OPTIMIZATION: Throttle to 500ms (2 FPS).
    // This syncs with the CameraFeed throttle and gives the CPU breathing room.
    if (DateTime.now().difference(_lastProcessedTime).inMilliseconds < 300) return;

    _isProcessing = true;

    try {
      final inputImage = CameraService.inputImageFromCameraImage(image, _frontCamera!);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      double calculatedStress = _stressHistoryBuffer.isNotEmpty ? _stressHistoryBuffer.last : 50.0;
      String status = _currentStatus;
      Color color = _statusColor;
      String confidence = "0%";

      if (faces.isNotEmpty) {
        final face = faces.first;

        // DELEGATE TO ENGINE
        final result = CalibrationService().calculateStress(face);

        calculatedStress = result['score'];
        confidence = result['confidence'];
        final double smileProb = face.smilingProbability ?? 0.0;
        final double leftEye = face.leftEyeOpenProbability ?? 1.0;
        final double rightEye = face.rightEyeOpenProbability ?? 1.0;
        final double avgEyeOpen = (leftEye + rightEye) / 2.0;

        final double pitch = face.headEulerAngleX ?? 0.0;
        final double roll = face.headEulerAngleZ ?? 0.0;
        final double yaw = face.headEulerAngleY ?? 0.0;

        // --- LOGIC GATE 1: DISTRACTION FILTER ---
        if (yaw.abs() > 30) {
          confidence = "Distracted";
        } else {
          // --- LOGIC GATE 2: STRESS CALCULATION ---
          double score = 60.0;

          // FACTOR A: Smile
          score -= (smileProb * 40.0);

          // FACTOR B: Deep Focus (Healthy)
          if (pitch < -5 && pitch > -25 && avgEyeOpen > 0.7) {
            score -= 15.0;
          }

          // FACTOR C: Fatigue (Unhealthy)
          if (avgEyeOpen < 0.6) {
            score += (0.6 - avgEyeOpen) * 100;
          }

          // FACTOR D: Posture Collapse
          if (pitch < -25 || pitch > 20) {
            score += 15.0;
          }

          // FACTOR E: Confusion Tilt
          if (roll.abs() > 15) {
            score += (roll.abs() - 15);
          }

          calculatedStress = score.clamp(0.0, 100.0);
          confidence = "${(100 - yaw.abs()).toInt()}% Fidelity";
        }
      }

      // --- STABILIZATION ---
      _stressHistoryBuffer.add(calculatedStress);
      if (_stressHistoryBuffer.length > _smoothingWindow) {
        _stressHistoryBuffer.removeAt(0);
      }

      double stableStress = _stressHistoryBuffer.reduce((a, b) => a + b) / _stressHistoryBuffer.length;

      // --- STATUS CLASSIFICATION ---
      if (stableStress < 35) {
        status = "Relaxed";
        color = AppTheme.statuscodecalm;
      } else if (stableStress < 55) {
        status = "Focused";
        color = Colors.blue;
      } else if (stableStress < 75) {
        status = "Neutral";
        color = Colors.blueGrey;
      } else if (stableStress < 90) {
        status = "Strained";
        color = Colors.orange;
      } else {
        status = "High Stress";
        color = AppTheme.alertCoral;
      }

      if (mounted) {
        setState(() {
          // Update graph speed to match 2 FPS (0.5s steps)
          _timeCounter += 0.5;
          _stressPoints.add(FlSpot(_timeCounter, stableStress));
          if (_stressPoints.length > 50) _stressPoints.removeAt(0);

          _currentStatus = status;
          _statusColor = color;
          _confidenceScore = confidence;

          StressData().update(stableStress, status);

          _lastProcessedTime = DateTime.now();
        });
      }

    } catch (e) {
      debugPrint("AI Processing Error: $e");
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
                      child: ValueListenableBuilder<File?>(
                        valueListenable: StressData().profileImageNotifier,
                        builder: (context, profileFile, child) {
                          return CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey,
                            backgroundImage: profileFile != null ? FileImage(profileFile) : null,
                            child: profileFile == null ? const Icon(Icons.person, color: Colors.white) : null,
                          );
                        },
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