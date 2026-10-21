import 'dart:convert';

import 'package:activ_user_app/core/network/api_media.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// Renders an SVG served by the ACTIV media API.
///
/// Fetches the raw SVG bytes, renders them through [SvgPicture.network]
/// semantics and falls back to [fallbackAsset] when the network SVG is
/// unavailable (offline / 404). SHA-256 keyed in-memory cache keeps repeated
/// renders cheap while the OS-level HTTP cache retains the bytes between runs.
class AppSvgNetwork extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  final String fallbackAsset;

  const AppSvgNetwork(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    this.fallbackAsset = 'assets/images/turf.jpg',
  });

  @override
  State<AppSvgNetwork> createState() => _AppSvgNetworkState();
}

class _AppSvgNetworkState extends State<AppSvgNetwork> {
  static final Map<String, String> _svgCache = {};
  static const _svgCacheLimit = 128;

  late String _absoluteUrl;
  String? _bytes;

  @override
  void initState() {
    super.initState();
    _absoluteUrl = ApiMedia.resolve(widget.url);
    _load();
  }

  @override
  void didUpdateWidget(covariant AppSvgNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = ApiMedia.resolve(widget.url);
    if (next != _absoluteUrl) {
      _absoluteUrl = next;
      _load();
    }
  }

  Future<void> _load() async {
    final cached = _svgCache[_absoluteUrl];
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }
    try {
      final response = await http.get(Uri.parse(_absoluteUrl));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final text = utf8.decode(response.bodyBytes);
        _cache(_absoluteUrl, text);
        setState(() => _bytes = text);
      }
    } catch (_) {
      // Offline: fall through to the bundled fallback asset.
    }
  }

  void _cache(String url, String bytes) {
    if (_svgCache.length >= _svgCacheLimit) {
      _svgCache.remove(_svgCache.keys.first);
    }
    _svgCache[url] = bytes;
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return _buildFallback();
    }

    return SvgPicture.string(
      bytes,
      width: widget.width,
      height: widget.height,
      colorFilter: widget.color != null
          ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
          : null,
      fit: widget.fit,
      placeholderBuilder: (_) => _buildFallback(),
      errorBuilder: (_, _, _) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    if (widget.fallbackAsset.toLowerCase().endsWith('.svg')) {
      return AppSvgAsset(
        widget.fallbackAsset,
        width: widget.width,
        height: widget.height,
        color: widget.color,
        fit: widget.fit,
      );
    }

    return Image.asset(
      widget.fallbackAsset,
      width: widget.width,
      height: widget.height,
      color: widget.color,
      fit: widget.fit,
      errorBuilder: (_, _, _) =>
          SizedBox(width: widget.width, height: widget.height),
    );
  }
}

/// Renders a bundled SVG asset (the offline fallback for [AppSvgNetwork]).
class AppSvgAsset extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const AppSvgAsset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      fit: fit,
    );
  }
}
