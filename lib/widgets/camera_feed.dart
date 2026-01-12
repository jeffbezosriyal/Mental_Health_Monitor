import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:stress_detection_app/main.dart';
import 'package:stress_detection_app/core/theme.dart';

class CameraFeed extends StatefulWidget {
  final Function(CameraImage)? onFrame;
  final String status;
  final Color statusColor;

  const CameraFeed({
    super.key,
    this.onFrame,
    this.status = "Calm",
    this.statusColor = AppTheme.statuscodecalm,
  });

  @override
  State<CameraFeed> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  CameraController? _controller;
  bool _isInitialized = false;
  int _frameSkipCounter = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;

    final frontCam = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCam,
      // OPTIMIZATION 1: LOW Resolution
      // drastically reduces heat generation.
      // Face detection works perfectly fine at 320x240 for selfie distance.
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      if (widget.onFrame != null) {
        await _controller!.startImageStream((CameraImage image) {
          // OPTIMIZATION 2: Heavy Throttling at Source
          // Standard camera is 30 FPS.
          // % 15 means we process 2 frames per second (30/15 = 2).
          // This eliminates buffer overflows and keeps the CPU cool.
          _frameSkipCounter++;
          if (_frameSkipCounter % 10 == 0) {
            widget.onFrame!(image);
            _frameSkipCounter = 0;
          }
        });
      }
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double borderRadiusValue = 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            border: Border.all(
              color: widget.statusColor,
              width: 3,
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(borderRadiusValue),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            child: _isInitialized
                ? SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 100,
                  height: 100 * _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
                : const Center(
              child: Icon(Icons.videocam_off, color: Colors.grey, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Status: ${widget.status}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.statusColor,
          ),
        ),
      ],
    );
  }
}