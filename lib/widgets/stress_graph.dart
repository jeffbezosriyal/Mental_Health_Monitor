import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stress_detection_app/core/theme.dart';

class StressGraph extends StatelessWidget {
  final List<FlSpot> dataPoints;
  final double maxX;
  final Color graphColor;

  const StressGraph({
    super.key,
    required this.dataPoints,
    required this.maxX,
    required this.graphColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration.copyWith(color: const Color(0xFFECEFF1)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Text("Live History", style: AppTheme.headingStyle),
            const SizedBox(height: 20),
            Expanded(
              child: dataPoints.isEmpty
                  ? const Center(child: Text("Waiting for data..."))
                  : LineChart(
                LineChartData(
                  // 1. Keep clipping to contain the graph inside the box
                  clipData: const FlClipData.all(),

                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),

                  // 2. THE FIX: Add buffer space to Top (110) and Bottom (-10)
                  // This allows the line thickness to render fully without being cut off
                  minY: -10,
                  maxY: 110,

                  // Sliding Window X-Axis
                  minX: maxX > 5 ? maxX - 5 : 0,
                  maxX: maxX > 5 ? maxX : 5,

                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: graphColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            graphColor.withOpacity(0.4),
                            graphColor.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}