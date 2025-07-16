import 'package:flutter/material.dart';

class QRScannerOverlayWidget extends StatelessWidget {
  final bool isScanning;
  final double size;

  const QRScannerOverlayWidget({
    Key? key,
    required this.isScanning,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            border: Border.all(width: 2),
            borderRadius: BorderRadius.circular(12)),
        child: Stack(children: [
          // Corner brackets
          ...List.generate(4, (index) {
            return _buildCornerBracket(index);
          }),

          // Center crosshair
          Center(
              child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(border: Border.all(width: 2)),
                  child: const Icon(Icons.add,
                      color: Colors.transparent, size: 16))),
        ]));
  }

  Widget _buildCornerBracket(int index) {
    final isTop = index < 2;
    final isLeft = index % 2 == 0;

    return Positioned(
        top: isTop ? -2 : null,
        bottom: !isTop ? -2 : null,
        left: isLeft ? -2 : null,
        right: !isLeft ? -2 : null,
        child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                border: Border(
                    top: isTop ? BorderSide(width: 4) : BorderSide.none,
                    bottom: !isTop ? BorderSide(width: 4) : BorderSide.none,
                    left: isLeft ? BorderSide(width: 4) : BorderSide.none,
                    right: !isLeft ? BorderSide(width: 4) : BorderSide.none))));
  }
}
