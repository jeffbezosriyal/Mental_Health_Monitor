import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  static InputImage inputImageFromCameraImage(CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    var rotation = InputImageRotation.rotation0deg;

    // Android vs iOS rotation handling
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_currentOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        // Front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // Back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ?? InputImageRotation.rotation0deg;
    }

    // Handle Image Format
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    // Combine all planes into one byte list
    final allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // NEW: Use InputImageMetadata instead of InputImageData
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation, // derived above
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow, // Simplification: only first plane needed
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  // Helper to detect device orientation (Simple version)
  // You can install 'native_device_orientation' package for perfect accuracy,
  // or just assume PortraitUp (0) for a simple test.
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  static const _currentOrientation = DeviceOrientation.portraitUp;
}