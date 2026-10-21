import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String fallbackAsset;

  const AppNetworkImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.fallbackAsset = 'assets/images/turf.jpg',
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = width == null
        ? null
        : (width! * devicePixelRatio).round();
    final cacheHeight = height == null
        ? null
        : (height! * devicePixelRatio).round();

    if (imagePath.startsWith('assets/')) {
      imageWidget = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    } else if (imagePath.isEmpty) {
      imageWidget = _fallback(context);
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => _fallback(context),
        errorWidget: (context, url, error) => _fallback(context),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1A1A1A),
      child: Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: const Color(0xFF1A1A1A),
          child: const Center(
            child: Icon(Icons.sports, color: Color(0xFFDAFF50), size: 32),
          ),
        ),
      ),
    );
  }
}
