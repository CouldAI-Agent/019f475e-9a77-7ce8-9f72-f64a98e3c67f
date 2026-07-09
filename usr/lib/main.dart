import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magic Pen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MagicCanvasScreen(),
      },
    );
  }
}

class DrawingPoint {
  final Offset point;
  final Paint paint;

  DrawingPoint({required this.point, required this.paint});
}

class MagicCanvasScreen extends StatefulWidget {
  const MagicCanvasScreen({super.key});

  @override
  State<MagicCanvasScreen> createState() => _MagicCanvasScreenState();
}

class _MagicCanvasScreenState extends State<MagicCanvasScreen> {
  final List<DrawingPoint?> _points = [];
  final Set<int> _activePointers = {};
  
  final List<Color> _colors = [
    Colors.cyanAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
  ];
  int _currentColorIndex = 0;

  void _cycleColor() {
    setState(() {
      _currentColorIndex = (_currentColorIndex + 1) % _colors.length;
    });
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  Paint _getCurrentPaint() {
    return Paint()
      ..color = _colors[_currentColorIndex]
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    
    if (_activePointers.length == 2) {
      _cycleColor();
      // Add null to break the line
      setState(() {
        _points.add(null);
      });
    } else if (_activePointers.length == 3) {
      _clearCanvas();
    } else if (_activePointers.length == 1) {
      setState(() {
        _points.add(
          DrawingPoint(
            point: event.localPosition,
            paint: _getCurrentPaint(),
          ),
        );
      });
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointers.length == 1 && _activePointers.contains(event.pointer)) {
      setState(() {
        _points.add(
          DrawingPoint(
            point: event.localPosition,
            paint: _getCurrentPaint(),
          ),
        );
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) {
      setState(() {
        _points.add(null);
      });
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) {
      setState(() {
        _points.add(null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Canvas
          Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: GlowPainter(points: _points),
              ),
            ),
          ),
          // Instructions Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Column(
                children: [
                  Text(
                    'Magic Pen',
                    style: TextStyle(
                      color: _colors[_currentColorIndex],
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: _colors[_currentColorIndex],
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1 Finger: Draw  •  2 Fingers: Change Color  •  3 Fingers: Clear',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlowPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  GlowPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Draw the glow
        canvas.drawLine(
          points[i]!.point,
          points[i + 1]!.point,
          points[i]!.paint,
        );
        
        // Draw the core line (brighter, thinner)
        final corePaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = points[i]!.paint.strokeWidth * 0.4;
          
        canvas.drawLine(
          points[i]!.point,
          points[i + 1]!.point,
          corePaint,
        );
      } else if (points[i] != null && points[i + 1] == null) {
        // Draw single dot
        canvas.drawPoints(
          PointMode.points,
          [points[i]!.point],
          points[i]!.paint,
        );
        
        final corePaint = Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = points[i]!.paint.strokeWidth * 0.4;
          
        canvas.drawPoints(
          PointMode.points,
          [points[i]!.point],
          corePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GlowPainter oldDelegate) {
    return true; // Simple approach for dynamic drawing
  }
}
