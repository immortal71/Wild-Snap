import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PointsCounter extends StatefulWidget {
  final int targetValue;
  final TextStyle? style;
  final Duration duration;

  const PointsCounter({
    super.key,
    required this.targetValue,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PointsCounter> createState() => _PointsCounterState();
}

class _PointsCounterState extends State<PointsCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _animation.addListener(() {
      setState(() {
        _displayValue = (_animation.value * widget.targetValue).round();
      });
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(PointsCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '+$_displayValue',
      style: widget.style ??
          GoogleFonts.jetBrainsMono(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: AppColors.accentPrimary,
          ),
    );
  }
}
