import 'dart:async';
import 'package:activ_user_app/core/constants/app_assets.dart';
import 'package:activ_user_app/shared/widgets/app_svg.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  final String hintText;
  final List<String>? animatedHints;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search for venues near you',
    this.animatedHints,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;
  Timer? _hintTimer;
  int _currentHintIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _isFocused = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChange);

    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChange);

    if (widget.animatedHints != null && widget.animatedHints!.isNotEmpty) {
      _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && _controller.text.isEmpty) {
          setState(() {
            _currentHintIndex =
                (_currentHintIndex + 1) % widget.animatedHints!.length;
          });
        }
      });
    }
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _handleTextChange() {
    if (mounted &&
        widget.animatedHints != null &&
        widget.animatedHints!.isNotEmpty) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _hintTimer?.cancel();
    _controller.removeListener(_handleTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_isFocused && !widget.readOnly)
              ? AppColors.primary
              : AppColors.lightGreyBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          AppSvg(
            AppAssets.search,
            color: AppColors.greyBorder,
            height: 22,
            width: 22,
          ),
          const SizedBox(width: 12), // 16px gap
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (widget.animatedHints != null &&
                    widget.animatedHints!.isNotEmpty &&
                    _controller.text.isEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    layoutBuilder:
                        (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          final inAnimation = Tween<Offset>(
                            begin: const Offset(0.0, 0.5),
                            end: Offset.zero,
                          ).animate(animation);
                          final outAnimation = Tween<Offset>(
                            begin: const Offset(0.0, -0.5),
                            end: Offset.zero,
                          ).animate(animation);

                          final isIncoming =
                              child.key == ValueKey<int>(_currentHintIndex);

                          return ClipRect(
                            child: SlideTransition(
                              position: isIncoming ? inAnimation : outAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                          );
                        },
                    child: Text(
                      widget.animatedHints![_currentHintIndex],
                      key: ValueKey<int>(_currentHintIndex),
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 16,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  onChanged: widget.onChanged,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    hintText:
                        (widget.animatedHints != null &&
                            widget.animatedHints!.isNotEmpty)
                        ? ''
                        : widget.hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 16,
                      height: 1.0,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
