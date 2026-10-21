import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;
  final bool isWhite;

  const AppLogo({
    super.key,
    this.width = 100.0,
    this.height = 100.0,
    this.color,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      isWhite ? AppAssets.logoWhite : AppAssets.logo,
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null);
  }
}
