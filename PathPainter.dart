import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PathDrawer extends CustomPainter {
  final List<dynamic> pathPoints;

  PathDrawer(this.pathPoints);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    if (pathPoints.isNotEmpty) {
      var firstPoint = pathPoints[0];
      Path path = Path();
      path.moveTo(firstPoint['x'].toDouble(), firstPoint['y'].toDouble());
      for (var point in pathPoints) {
        path.lineTo(point['x'].toDouble(), point['y'].toDouble());
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ImagePainter extends CustomPainter {
  final Uint8List imageBytes;

  ImagePainter(this.imageBytes);

  @override
  void paint(Canvas canvas, Size size) async {
    final paint = Paint();

    // Decode image and draw it on canvas
    final ui.Image image = await _loadImage(Uint8List.fromList(imageBytes));
    canvas.drawImage(image, Offset.zero, paint);
  }

  Future<ui.Image> _loadImage(Uint8List imageBytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}