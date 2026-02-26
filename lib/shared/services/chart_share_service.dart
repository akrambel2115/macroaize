import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:macroaize/shared/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ChartShareService {
  const ChartShareService._();

  static Future<void> shareChartBoundary({
    required GlobalKey boundaryKey,
    Rect? sharePositionOrigin,
    String? text,
  }) async {
    try {
      final context = boundaryKey.currentContext;
      if (context == null) {
        NotificationService.showError('Unable to share this chart');
        return;
      }

      final renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        NotificationService.showError('Unable to share this chart');
        return;
      }

      final ui.Image image = await renderObject.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        NotificationService.showError('Unable to share this chart');
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/chart_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: text ?? 'Check out my progress on Macroaize!',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      log('SHARE_CHART_ERROR => $e');
      NotificationService.showError('Unable to share this chart');
    }
  }
}
