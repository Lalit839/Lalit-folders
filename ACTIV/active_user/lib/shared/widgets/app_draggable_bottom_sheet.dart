import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet_header.dart';

Future<T?> showAppDraggableBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(
    BuildContext context,
    ScrollController scrollController,
  )
  builder,
  double initialChildSize = 0.45,
  double minChildSize = 0.35,
  double maxChildSize = 0.9,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  AppBottomSheetHeader(title: title),
                  const SizedBox(height: 24),
                  Expanded(child: builder(context, scrollController)),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
