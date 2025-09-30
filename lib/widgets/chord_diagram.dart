import 'package:flutter/material.dart';

import '../models/chord.dart';

class ChordDiagram extends StatelessWidget {
  const ChordDiagram({super.key, required this.chord});

  final Chord chord;

  @override
  Widget build(BuildContext context) {
    final int fretCount = (chord.maxFret <= 3) ? 4 : chord.maxFret + 1;
    final double height = 60 + fretCount * 48;
    return SizedBox(
      width: 220,
      height: height,
      child: CustomPaint(
        painter: _ChordDiagramPainter(chord: chord, fretCount: fretCount),
      ),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  _ChordDiagramPainter({required this.chord, required this.fretCount});

  final Chord chord;
  final int fretCount;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;

    const double topMargin = 32;
    const double bottomMargin = 36;
    const double sideMargin = 24;

    final double drawableHeight = size.height - topMargin - bottomMargin;
    final double fretGap = drawableHeight / fretCount;
    final double drawableWidth = size.width - (sideMargin * 2);
    final double stringGap = drawableWidth / 3;

    // Draw strings
    for (int i = 0; i < 4; i++) {
      final double x = sideMargin + i * stringGap;
      canvas.drawLine(Offset(x, topMargin), Offset(x, size.height - bottomMargin), linePaint);
    }

    // Draw frets
    for (int fret = 0; fret <= fretCount; fret++) {
      final double y = topMargin + fret * fretGap;
      canvas.drawLine(
        Offset(sideMargin, y),
        Offset(size.width - sideMargin, y),
        linePaint,
      );
    }

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Draw string labels and open string markers
    final List<int> frets = chord.stringFrets;
    for (int string = 0; string < 4; string++) {
      final double x = sideMargin + string * stringGap;
      final double openY = topMargin - 16;
      if (frets[string] == 0) {
        final Paint openPaint = Paint()
          ..color = linePaint.color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(x, openY), 10, openPaint);
      }
      textPainter.text = TextSpan(
        text: chord.stringLabel(string),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomMargin + 12),
      );
    }

    // Draw finger positions
    final Paint dotPaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;

    for (final ChordFingerPosition finger in chord.fingerPositions) {
      final double x = sideMargin + finger.stringIndex * stringGap;
      final double y = topMargin + (finger.fret - 0.5) * fretGap;
      canvas.drawCircle(Offset(x, y), 14, dotPaint);
      textPainter.text = TextSpan(
        text: finger.fingerNumber.toString(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
