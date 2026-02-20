import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// barcode scanning service
class BarcodeScanningService {
  BarcodeScanner? _barcodeScanner;
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  String? _lastScannedBarcode;

  // throttle settings
  static const Duration _scanThrottle = Duration(milliseconds: 500);
  static const Duration _debounceAfterSuccess = Duration(seconds: 2);

  BarcodeScanningService() {
    _barcodeScanner = BarcodeScanner(
      formats: [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upca,
        BarcodeFormat.upce,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
      ],
    );
  }

  // scan from camera
  Future<String?> scanBarcodeFromImage(CameraImage image) async {
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
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
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
            print('Barcode detected: $value (${barcode.format.name})');
          }
          return value;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning barcode: $e');
      }
    } finally {
      _isProcessing = false;
    }

    return null;
  }

  // convert for ml kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Determine the correct image format based on platform
      final InputImageFormat imageFormat;
      if (Platform.isAndroid) {
        imageFormat = InputImageFormat.nv21;
      } else if (Platform.isIOS) {
        imageFormat = InputImageFormat.bgra8888;
      } else {
        // Unsupported platform
        return null;
      }

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _getImageRotation(),
        format: imageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    } catch (e) {
      if (kDebugMode) {
        print('Error converting camera image: $e');
      }
      return null;
    }
  }


  InputImageRotation _getImageRotation() {
    if (Platform.isIOS) {
      // iOS camera images are pre-rotated to the correct orientation
      return InputImageRotation.rotation0deg;
    }
    // Android default portrait
    return InputImageRotation.rotation0deg;
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
