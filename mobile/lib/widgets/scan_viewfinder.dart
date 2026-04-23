import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScanViewfinder extends StatefulWidget {
  const ScanViewfinder({super.key});

  @override
  State<ScanViewfinder> createState() => _ScanViewfinderState();
}

class _ScanViewfinderState extends State<ScanViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = CurvedAnimation(parent: _scanController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewfinderHeight = constraints.maxHeight;
        return Stack(
          children: [
            // Corner brackets
            Positioned(top: 0, left: 0, child: _corner(true, true)),
            Positioned(top: 0, right: 0, child: _corner(true, false)),
            Positioned(bottom: 0, left: 0, child: _corner(false, true)),
            Positioned(bottom: 0, right: 0, child: _corner(false, false)),

            // Scan line — position is proportional to actual container height
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, _) {
                return Positioned(
                  top: _scanAnimation.value * viewfinderHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.accentPrimary.withOpacity(0.8),
                          AppColors.accentPrimary,
                          AppColors.accentPrimary.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPrimary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _corner(bool isTop, bool isLeft) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: _CornerPainter(
        isTop: isTop,
        isLeft: isLeft,
        color: AppColors.accentPrimary,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;
  final Color color;

  const _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const length = 20.0;
    const radius = 4.0;

    final path = Path();

    if (isTop && isLeft) {
      path.moveTo(0, length);
      path.lineTo(0, radius);
      path.arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius));
      path.lineTo(length, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(size.width - length, 0);
      path.lineTo(size.width - radius, 0);
      path.arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius));
      path.lineTo(size.width, length);
    } else if (!isTop && isLeft) {
      path.moveTo(0, size.height - length);
      path.lineTo(0, size.height - radius);
      path.arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius));
      path.lineTo(length, size.height);
    } else {
      path.moveTo(size.width - length, size.height);
      path.lineTo(size.width - radius, size.height);
      path.arcToPoint(
        Offset(size.width, size.height - radius),
        radius: const Radius.circular(radius),
      );
      path.lineTo(size.width, size.height - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.isTop != isTop || old.isLeft != isLeft || old.color != color;
}
