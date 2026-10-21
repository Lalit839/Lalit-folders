import 'package:flutter/material.dart';

class StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  StickyFilterDelegate({
    required this.child,
    required this.height,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Ensure background matches
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant StickyFilterDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
