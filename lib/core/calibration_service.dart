import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalibrationService {
  static final CalibrationService _instance = CalibrationService._internal();
  factory CalibrationService() => _instance;
  CalibrationService._internal();

  // -- Baselines (Default to 0 if not calibrated) --
  double _basePitch = -10.0; // Default: slight downward look for phone
  double _baseRoll = 0.0;
  double _baseYaw = 0.0;
  double _baseEyeOpen = 0.8;

  bool isCalibrated = false;

  Future<void> loadBaselines() async {
    final prefs = await SharedPreferences.getInstance();
    _basePitch = prefs.getDouble('base_pitch') ?? -10.0;
    _baseRoll = prefs.getDouble('base_roll') ?? 0.0;
    _baseYaw = prefs.getDouble('base_yaw') ?? 0.0;
    _baseEyeOpen = prefs.getDouble('base_eye') ?? 0.8;
    isCalibrated = prefs.containsKey('base_pitch');
  }

  Future<void> saveBaselines(List<Face> samples) async {
    if (samples.isEmpty) return;

    // Calculate Averages
    double sumPitch = 0, sumRoll = 0, sumYaw = 0, sumEye = 0;
    for (var face in samples) {
      sumPitch += face.headEulerAngleX ?? 0;
      sumRoll += face.headEulerAngleZ ?? 0;
      sumYaw += face.headEulerAngleY ?? 0;
      sumEye += ((face.leftEyeOpenProbability ?? 1) + (face.rightEyeOpenProbability ?? 1)) / 2;
    }

    _basePitch = sumPitch / samples.length;
    _baseRoll = sumRoll / samples.length;
    _baseYaw = sumYaw / samples.length;
    _baseEyeOpen = sumEye / samples.length;

    // Persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('base_pitch', _basePitch);
    await prefs.setDouble('base_roll', _baseRoll);
    await prefs.setDouble('base_yaw', _baseYaw);
    await prefs.setDouble('base_eye', _baseEyeOpen);

    isCalibrated = true;
  }

  // -- RELATIVE STRESS LOGIC --
  Map<String, dynamic> calculateStress(Face face) {
    double score = 60.0; // Base Score
    String debugReason = "Neutral";

    // 1. Get Live Values
    final double pitch = face.headEulerAngleX ?? 0.0;
    final double roll = face.headEulerAngleZ ?? 0.0;
    final double yaw = face.headEulerAngleY ?? 0.0;
    final double avgEye = ((face.leftEyeOpenProbability ?? 1) + (face.rightEyeOpenProbability ?? 1)) / 2;

    // 2. Calculate Deviations (Delta)
    final double deltaPitch = pitch - _basePitch;
    final double deltaRoll = roll - _baseRoll;
    final double deltaYaw = yaw - _baseYaw;
    final double deltaEye = _baseEyeOpen - avgEye;

    // 3. Logic Gates (Relative)

    // A. Distraction (Significant Yaw Deviation)
    if (deltaYaw.abs() > 25) {
      return {'score': 50.0, 'confidence': 'Distracted'};
    }

    // B. Smile Detection (Absolute - Smiling is always good)
    final double smile = face.smilingProbability ?? 0.0;
    if (smile > 0.5) {
      score -= (smile * 40.0);
      debugReason = "Smiling";
    }

    // C. Posture Collapse (Head drops significantly below baseline)
    // Threshold: 15 degrees lower than their "normal"
    if (deltaPitch < -15) {
      score += 20.0;
      debugReason = "Bad Posture";
    }

    // D. Focus (Head is steady and slightly up/forward from baseline)
    if (deltaPitch > -5 && deltaPitch < 5 && deltaEye < 0.1) {
      score -= 10.0;
      debugReason = "Focused";
    }

    // E. Fatigue (Eyes closing relative to baseline)
    if (deltaEye > 0.2) { // 20% more closed than normal
      score += (deltaEye * 100);
      debugReason = "Fatigue";
    }

    // F. Confusion/Strain (Head Tilt)
    if (deltaRoll.abs() > 10) {
      score += (deltaRoll.abs() * 0.5);
    }

    return {
      'score': score.clamp(0.0, 100.0),
      'confidence': '${(100 - (score/2)).toInt()}% match',
      'reason': debugReason
    };
  }
}