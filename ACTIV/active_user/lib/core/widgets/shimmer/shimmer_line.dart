import 'package:flutter/material.dart';

class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? color;

  const ShimmerLine({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.borderRadius = 6,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius)));
  }
}
