import 'package:flutter/material.dart';

class SelectedCourtsSection extends StatelessWidget {
  final List<Widget> children;

  const SelectedCourtsSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
