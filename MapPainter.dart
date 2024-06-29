import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MapPainter extends CustomPainter {
  final ui.Image image;
  final List<dynamic> path;
  final double rotationAngle;
  final Map<String, double> currentPosition;

  MapPainter({    
    required this.image,
    required this.path,
    required this.currentPosition,
    this.rotationAngle = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final imageRect = Offset.zero & size;

    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, srcRect, imageRect, paint);

    final pathPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; 
   
    final currentLocationPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final firstLastPointPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
      
    if (path.isNotEmpty) {
      Path drawPath = Path();

      double offsetX = size.width * 0.8; 
      double offsetY = size.height * 0.2; 
      double scale = 30;

      canvas.save();
      canvas.translate(offsetX, offsetY);
      canvas.rotate(rotationAngle);
      canvas.scale(-1,1);

      for (var i = 0; i < path.length; i++) {
        var point = path[i];
        double x = (point['x'] * scale);
        double y = (point['y'] * scale);
        if (i == 0) {
          drawPath.moveTo(x, y);
        } else {
          drawPath.lineTo(x, y);
        }
      }
      canvas.drawPath(drawPath, pathPaint);

      for (var i = 1; i < path.length; i++) {
        var point = path[i];
        double x = (point['x'] * scale);
        double y = (point['y'] * scale);
        canvas.drawCircle(Offset(x, y), 2.0, pathPaint..style = PaintingStyle.fill);
      if (i == 0 || i == path.length - 1) {
          canvas.drawCircle(Offset(x, y), 4.0, firstLastPointPaint);
        } else {
          canvas.drawCircle(Offset(x, y), 2.0, pathPaint..style = PaintingStyle.fill);
        }
      }
      int i= 0;
      var point = path[i];
      canvas.drawCircle(Offset((point['x'] * scale), (point['y'] * scale)), 4.0, firstLastPointPaint);

      double currentX = currentPosition['x']! * scale;
      double currentY = currentPosition['y']! * scale;
      canvas.drawCircle(Offset(currentX, currentY), 4.0, currentLocationPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
