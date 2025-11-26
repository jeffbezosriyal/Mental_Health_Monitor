class StressData {
  // Singleton pattern: Ensures both screens access the SAME data
  static final StressData _instance = StressData._internal();
  factory StressData() => _instance;
  StressData._internal();

  // The live data
  double currentStressValue = 50.0;
  String currentLabel = "Neutral";

  // Update function called by HomeMonitor
  void update(double value, String label) {
    currentStressValue = value;
    currentLabel = label;
  }
}