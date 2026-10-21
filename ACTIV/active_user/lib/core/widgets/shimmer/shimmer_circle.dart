import 'package:flutter/material.dart';

class ShimmerCircle extends StatelessWidget {
  final double radius;
  final Color? color;

  const ShimmerCircle({
    super.key,
    required this.radius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: BoxShape.circle));
  }
}
