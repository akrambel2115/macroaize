import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:flutter/foundation.dart';

// barcode scanning service
class BarcodeScanningService {
  BarcodeScanner? _barcodeScanner;
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  String? _lastScannedBarcode;

  // throttle settings – reduced for snappier detection
  static const Duration _scanThrottle = Duration(milliseconds: 100);
  static const Duration _debounceAfterSuccess = Duration(seconds: 1);

  BarcodeScanningService() {
    // No formats parameter → scan ALL barcode types by default.
    _barcodeScanner = BarcodeScanner();
  }

  // scan from camera
  Future<String?> scanBarcodeFromImage(
    CameraImage image, {
    required int sensorOrientation,
  }) async {
    // throttle scanning
    if (_isProcessing) return null;

    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < _scanThrottle) {
      return null;
    }

    // debounce after scan
    if (_lastScannedBarcode != null &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < _debounceAfterSuccess) {
      return null;
    }

    _isProcessing = true;
    _lastScanTime = now;

    try {
      final inputImage = _convertCameraImage(image, sensorOrientation);
      if (inputImage == null) {
        if (kDebugMode) {
          print('[Barcode] _convertCameraImage returned null '
              '(format: ${image.format.group}, '
              'planes: ${image.planes.length}, '
              'size: ${image.width}x${image.height})');
        }
        _isProcessing = false;
        return null;
      }

      final barcodes = await _barcodeScanner?.processImage(inputImage);

      if (barcodes != null && barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        final value = barcode.displayValue ?? barcode.rawValue;

        if (value != null && value.isNotEmpty) {
          _lastScannedBarcode = value;
          _lastScanTime = DateTime.now();
          if (kDebugMode) {
            print('[Barcode] Detected: $value (${barcode.format.name})');
          }
          return value;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Barcode] Error scanning: $e');
      }
    } finally {
      _isProcessing = false;
    }

    return null;
  }

  // convert for ml kit
  InputImage? _convertCameraImage(CameraImage image, int sensorOrientation) {
    try {
      final InputImageFormat imageFormat;
      final Uint8List bytes;

      if (Platform.isAndroid) {
        // On Android, prefer NV21 (single buffer). If the camera provides
        // yuv_420_888, use only the first plane (Y plane) as NV21 when the
        // format group matches, or fall back to nv21 if that's what we got.
        if (image.format.group == ImageFormatGroup.nv21) {
          imageFormat = InputImageFormat.nv21;
        } else if (image.format.group == ImageFormatGroup.yuv420) {
          imageFormat = InputImageFormat.yuv_420_888;
        } else {
          imageFormat = InputImageFormat.nv21;
        }
        // Concatenate all planes for NV21 / YUV420.
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
      } else if (Platform.isIOS) {
        imageFormat = InputImageFormat.bgra8888;
        // iOS BGRA8888 has a single plane.
        bytes = image.planes[0].bytes;
      } else {
        return null;
      }

      // Determine the rotation to pass to ML Kit.
      final InputImageRotation rotation;
      if (Platform.isIOS) {
        // On iOS the camera plugin already delivers frames through an
        // AVCaptureVideoDataOutput whose connection is locked to portrait,
        // so the pixel buffer is upright.  Telling ML Kit to rotate again
        // breaks detection.
        rotation = InputImageRotation.rotation0deg;
      } else {
        rotation = _rotationFromDegrees(sensorOrientation);
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: imageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      if (kDebugMode) {
        print('[Barcode] Error converting camera image: $e');
      }
      return null;
    }
  }

  /// Map the camera sensor orientation (0/90/180/270) to
  /// [InputImageRotation].
  InputImageRotation _rotationFromDegrees(int degrees) {
    switch (degrees) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  // reset last scan
  void reset() {
    _lastScannedBarcode = null;
    _lastScanTime = null;
  }

  // dispose resources
  void dispose() {
    _barcodeScanner?.close();
    _barcodeScanner = null;
  }
}
