import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/services/image_downloader.dart';
import 'package:activ_user_app/shared/widgets/app_text.dart';
import 'package:activ_user_app/shared/widgets/app_bottom_sheet.dart';
import 'package:activ_user_app/shared/widgets/app_divider.dart';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ShareActivityBottomSheet extends StatefulWidget {
  final bool isWeekView;
  final Widget contentToCapture;
  final DateTime date;
  final int activeDaysCount;

  const ShareActivityBottomSheet({
    super.key,
    required this.isWeekView,
    required this.contentToCapture,
    required this.date,
    required this.activeDaysCount,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isWeekView,
    required Widget contentToCapture,
    required DateTime date,
    required int activeDaysCount,
  }) {
    return showAppBottomSheet(
      context: context,
      title: 'Share Your Activity',
      child: ShareActivityBottomSheet(
        isWeekView: isWeekView,
        contentToCapture: contentToCapture,
        date: date,
        activeDaysCount: activeDaysCount,
      ),
    );
  }

  @override
  State<ShareActivityBottomSheet> createState() => _ShareActivityBottomSheetState();
}

class _ShareActivityBottomSheetState extends State<ShareActivityBottomSheet> {
  final GlobalKey _captureKey = GlobalKey();
  bool _capturing = false;

  String get _fileName => widget.isWeekView ? 'activ-week.png' : 'activ-day.png';

  Future<Uint8List> _capture() async {
    final boundary = _captureKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _shareImage() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final bytes = await _capture();
      await SharePlus.instance.share(
        ShareParams(
          text: widget.isWeekView ? 'My ACTIV week is on fire!' : 'My ACTIV day, my moves!',
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: _fileName)],
        ),
      );
    } catch (error) {
      debugPrint('Share failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _download() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final bytes = await _capture();
      await downloadImageFile(_fileName, bytes);
    } catch (error) {
      debugPrint('Download failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download image')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.isWeekView
        ? '${DateFormat('dd').format(widget.date)} - ${DateFormat('dd MMMM yyyy').format(widget.date.add(const Duration(days: 6)))}'
        : DateFormat('dd MMMM yyyy').format(widget.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Capture Area
          RepaintBoundary(
            key: _captureKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blackColor2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.bold(
                        'ACTIV',
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                      AppText.small(
                        formattedDate,
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.bold(
                        widget.isWeekView ? 'MY WEEK\nMY MOVES' : 'MY DAY\nMY MOVES',
                        color: AppColors.primary,
                        fontSize: 24,
                        maxLines: 2,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText.small(
                            'Consistency Level',
                            color: AppColors.grey99,
                            fontSize: 10,
                          ),
                          if (widget.isWeekView) ...[
                            const SizedBox(height: 4),
                            AppText.bold(
                              '${widget.activeDaysCount} Out of 7 Days',
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            const AppDivider(verticalPadding: 0),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // The actual week grid or day list widget
                  if (widget.isWeekView)
                    Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Image.asset(
                            AppAssets.calendarChart,
                            fit: BoxFit.cover,
                            height: 150,
                          ),
                        ),
                        widget.contentToCapture,
                      ],
                    )
                  else
                    widget.contentToCapture,
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Share Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShareIcon(
                Icons.download_outlined,
                'Download',
                isLoading: _capturing,
                onTap: _download,
              ),
              _buildShareIcon(
                Icons.share_outlined,
                'Share',
                isLoading: _capturing,
                onTap: _shareImage,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText.small(
            'Screenshot preview as PNG — share to WhatsApp, Instagram or download.',
            color: AppColors.grey99,
            fontSize: 11,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShareIcon(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isLoading ? null : onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: AppColors.textPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        AppText.small(label, color: AppColors.textPrimary, fontSize: 12),
      ],
    );
  }
}