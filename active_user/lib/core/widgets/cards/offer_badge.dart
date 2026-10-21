import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class OfferBadge extends StatelessWidget {
  final String discount;

  const OfferBadge({super.key, required this.discount});

  @override
  Widget build(BuildContext context) {
    final normalized = discount.trim();
    final text = normalized.isNotEmpty ? normalized : 'OFFERS';

    return Positioned(
      top: 8, // Shifted down from the top edge
      left: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. The dark green fold (triangle connecting ribbon to card edge)
          Positioned(
            left: 0,
            top: 33.5,
            child: CustomPaint(
              size: const Size(16, 28),
              painter: _FoldPainter(),
            ),
          ),
          // 2. The main ribbon
          ClipPath(
            clipper: _RibbonClipper(),
            child: Container(
              height: 45.5,
              padding: const EdgeInsets.only(
                left: 4.0,
                right: 18.0,
              ), // Adjust left/right padding for desired spacing
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDAFF50), Color(0xFFFFF050)],
                ),
              ),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: const Offset(
                  0,
                  2,
                ), // Slight vertical adjustment to center the slanted text
                child: Transform.rotate(
                  angle: -0.206, // Matches the slant
                  child: AppText.bold(
                    text,
                    color: Colors.black,
                    fontSize: 14.6,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFBED710);
    final path = Path();
    path.moveTo(0, 11); // Tucked 1px under ribbon's bottom-left corner
    path.lineTo(size.width, 0); // Top right, tucked under ribbon
    path.lineTo(
      size.width,
      size.height,
    ); // Bottom tip, pointing INWARDS (not touching card edge)
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final slantY = 15.0; // The top-left starts 15px down
    final rightBottomY = size.height - slantY;

    final slope = -slantY / size.width;
    final perpSlope = -1 / slope;

    // Calculate top-right tip to make a perpendicular cut (ensures equal & centered tails)
    final topRightX =
        (slantY - rightBottomY + perpSlope * size.width) / (perpSlope - slope);
    final topRightY = slantY + slope * topRightX;

    final cutX = size.width - 12;
    final topYAtCut = slantY + slope * cutX;
    final bottomYAtCut = size.height + slope * cutX;
    final cutY =
        (topYAtCut + bottomYAtCut) /
        2; // Perfectly center-aligned on the ribbon

    path.moveTo(0, slantY); // Top-Left
    path.lineTo(topRightX, topRightY); // Top-Right tip
    path.lineTo(cutX, cutY); // Inner Cut
    path.lineTo(size.width, rightBottomY); // Bottom-Right tip
    path.lineTo(0, size.height); // Bottom-Left
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
