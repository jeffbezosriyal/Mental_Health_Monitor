import 'dart:io';
import 'package:flutter/foundation.dart';

class StressData {
  // Singleton pattern: Ensures both screens access the SAME data
  static final StressData _instance = StressData._internal();
  factory StressData() => _instance;
  StressData._internal();

  // The live data
  double currentStressValue = 50.0;
  String currentLabel = "Neutral";

  // Shared Profile Image State
  final ValueNotifier<File?> profileImageNotifier = ValueNotifier<File?>(null);

  // NEW: Shared User Name State (Default: Mr. John Doe)
  final ValueNotifier<String> userNameNotifier = ValueNotifier<String>("Mr. John Doe");

  // Update function called by HomeMonitor for stress
  void update(double value, String label) {
    currentStressValue = value;
    currentLabel = label;
  }

  // Update function for Profile Image
  void updateProfileImage(File? image) {
    profileImageNotifier.value = image;
  }

  // NEW: Update function for User Name
  void updateUserName(String name) {
    userNameNotifier.value = name;
  }
}