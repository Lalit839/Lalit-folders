// import 'package:activ_user_app/core/constants/app_fonts.dart';
// import 'package:flutter/material.dart';

// class AppText extends StatelessWidget {
//   final String text;
//   final TextStyle? style;
//   final Color? color;
//   final double? fontSize;
//   final FontWeight? fontWeight;
//   final TextAlign? textAlign;
//   final TextOverflow? overflow;
//   final int? maxLines;
//   final double? height;
//   final double? letterSpacing;
//   final String? fontFamily;

//   const AppText(
//     this.text, {
//     super.key,
//     this.style,
//     this.color,
//     this.fontSize,
//     this.fontWeight,
//     this.textAlign,
//     this.overflow,
//     this.maxLines,
//     this.height,
//     this.letterSpacing,
//     this.fontFamily,
//   });

//   // Headline Large (32px)
//   factory AppText.bold(
//     String text, {
//     Key? key,
//     Color? color,
//     FontWeight? fontWeight,
//     TextAlign? textAlign,
//     TextOverflow? overflow,
//     int? maxLines,
//     double? height,
//     double? letterSpacing,
//     String? fontFamily,
//     double? fontSize,
//   }) {
//     return AppText(
//       text,
//       key: key,
//       style: TextStyle(
//         fontSize: fontSize ?? 32,
//         fontWeight: fontWeight ?? FontWeight.bold,
//         fontFamily: fontFamily ?? AppFonts.bold,
//       ),
//       color: color,
//       fontWeight: fontWeight,
//       textAlign: textAlign,
//       overflow: overflow,
//       maxLines: maxLines,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: fontFamily,
//     );
//   }

//   // Headline Medium (24px)
//   factory AppText.bold(
//     String text, {
//     Key? key,
//     Color? color,
//     FontWeight? fontWeight,
//     TextAlign? textAlign,
//     TextOverflow? overflow,
//     int? maxLines,
//     double? height,
//     double? letterSpacing,
//     String? fontFamily,
//     double? fontSize,
//   }) {
//     return AppText(
//       text,
//       key: key,
//       style: TextStyle(
//         fontSize: fontSize ?? 24,
//         fontWeight: fontWeight ?? FontWeight.bold,
//         fontFamily: fontFamily,
//       ),
//       color: color,
//       fontWeight: fontWeight,
//       textAlign: textAlign,
//       overflow: overflow,
//       maxLines: maxLines,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: fontFamily,
//     );
//   }

//   // Title Large (20px)
//   factory AppText.bold(
//     String text, {
//     Key? key,
//     Color? color,
//     FontWeight? fontWeight,
//     TextAlign? textAlign,
//     TextOverflow? overflow,
//     int? maxLines,
//     double? height,
//     double? letterSpacing,
//     String? fontFamily,
//     double? fontSize,
//   }) {
//     return AppText(
//       text,
//       key: key,
//       style: TextStyle(
//         fontSize: fontSize ?? 20,
//         fontWeight: fontWeight ?? FontWeight.bold,
//         fontFamily: fontFamily ?? AppFonts.bold,
//       ),
//       color: color,
//       fontWeight: fontWeight,
//       textAlign: textAlign,
//       overflow: overflow,
//       maxLines: maxLines,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: fontFamily,
//     );
//   }

//   // Title Medium (16px, Semibold)
//   factory AppText.medium(
//     String text, {
//     Key? key,
//     Color? color,
//     FontWeight? fontWeight,
//     TextAlign? textAlign,
//     TextOverflow? overflow,
//     int? maxLines,
//     double? height,
//     double? letterSpacing,
//     String? fontFamily,
//     double? fontSize,
//   }) {
//     return AppText(
//       text,
//       key: key,
//       style: TextStyle(
//         fontSize: fontSize ?? 16,
//         fontWeight: fontWeight ?? FontWeight.w500,
//         fontFamily: fontFamily ?? AppFonts.medium,
//       ),
//       color: color,
//       fontWeight: fontWeight,
//       textAlign: textAlign,
//       overflow: overflow,
//       maxLines: maxLines,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: fontFamily,
//     );
//   }

//   // Body Large (16px, Regular)
//   factory AppText(
//     String text, {
//     Key? key,
//     Color? color,
//     FontWeight? fontWeight,
//     TextAlign? textAlign,
//     TextOverflow? overflow,
//     int? maxLines,
//     double? height,
//     double? letterSpacing,
//     String? fontFamily,
//     double? fontSize,
//     TextDecoration? decoration,
//   }) {
//     return AppText(
//       text,
//       key: key,
//       style: TextStyle(
//         fontSize: fontSize ?? 16,
//         fontWeight: fontWeight ?? FontWeight.normal,
//         fontFamily: fontFamily ?? AppFonts.regular,
//         decoration: decoration ?? TextDecoration.none,
//       ),
//       color: color,
//       fontWeight: fontWeight,
//       textAlign: textAlign,
//       overflow: overflow,
//       maxLines: maxLines,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: fontFamily,
//     );
//   }

//   // Body Medium (14px, Regular)
//   factory AppText(
//     String text, {
//     Key? key,
//     Color? color,
//     FontWeight? fontWeight,
//     TextAlign? textAlign,
//     TextOverflow? overflow,
//     int? maxLines,
//     double? height,
//     double? letterSpacing,
//     String? fontFamily,
//     double? fontSize,
//   }) {
//     return AppText(
//       text,
//       key: key,
//       style: TextStyle(
//         fontSize: fontSize ?? 14,
//         fontWeight: fontWeight ?? FontWeight.normal,
//         fontFamily: fontFamily ?? AppFonts.regular,
//       ),
//       color: color,
//       fontWeight: fontWeight,
//       textAlign: textAlign,
//       overflow: overflow,
//       maxLines: maxLines,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: fontFamily,
//     );
//   }

//   // Label Large (14px, Bold)
//   factory AppText.medium(
//     String text, {
//     Key? key,
//     Color? color,
//     FontWeight? fontWeight,
//     TextAlign? textAlign,
//     TextOverflow? overflow,
//     int? maxLines,
//     double? height,
//     double? letterSpacing,
//     String? fontFamily,
//     double? fontSize,
//   }) {
//     return AppText(
//       text,
//       key: key,
//       style: TextStyle(
//         fontSize: fontSize ?? 14,
//         fontWeight: fontWeight ?? FontWeight.bold,
//         fontFamily: fontFamily,
//       ),
//       color: color,
//       fontWeight: fontWeight,
//       textAlign: textAlign,
//       overflow: overflow,
//       maxLines: maxLines,
//       height: height,
//       letterSpacing: letterSpacing,
//       fontFamily: fontFamily,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeStyle = style ?? Theme.of(context).textTheme.bodyMedium;
//     return Text(
//       text,
//       style: themeStyle?.copyWith(
//         color: color,
//         fontSize: fontSize,
//         fontWeight: fontWeight,
//         height: height,
//         letterSpacing: letterSpacing,
//         fontFamily: fontFamily,
//       ),
//       textAlign: textAlign,
//       overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
//       maxLines: maxLines,
//     );
//   }
// }

import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/constants/app_fonts.dart';
import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;
  final String fontFamily;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final double? height;
  final double? letterSpacing;
  final TextDecoration? decoration;
  final bool? softWrap;

  const AppText(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 14,
    this.fontFamily = AppFonts.regular,
    this.fontWeight,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.height,
    this.letterSpacing,
    this.decoration,
    this.softWrap,
  });

  /// Bold text
  /// Default: 18px
  factory AppText.bold(
    String text, {
    Key? key,
    Color? color,
    double fontSize = 18,
    FontWeight? fontWeight = FontWeight.w700,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    bool? softWrap,
  }) {
    return AppText(
      text,
      key: key,
      color: color,
      fontSize: fontSize,
      fontFamily: AppFonts.bold,
      fontWeight: fontWeight,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      softWrap: softWrap,
    );
  }

  /// Medium text
  /// Default: 14px
  factory AppText.medium(
    String text, {
    Key? key,
    Color? color,
    double fontSize = 16,
    FontWeight? fontWeight = FontWeight.w500,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    bool? softWrap,
  }) {
    return AppText(
      text,
      key: key,
      color: color,
      fontSize: fontSize,
      fontFamily: AppFonts.medium,
      fontWeight: fontWeight,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      softWrap: softWrap,
    );
  }

  /// Small regular text
  /// Default: 12px
  factory AppText.small(
    String text, {
    Key? key,
    Color? color,
    double fontSize = 14,
    FontWeight? fontWeight = FontWeight.w400,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    bool? softWrap,
  }) {
    return AppText(
      text,
      key: key,
      color: color,
      fontSize: fontSize,
      fontFamily: AppFonts.regular,
      fontWeight: fontWeight,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      softWrap: softWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: softWrap,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      ),
    );
  }
}
