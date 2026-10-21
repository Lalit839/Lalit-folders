import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/core/widgets/common/sub_section_header.dart';

class VenueExpandableSection extends StatefulWidget {
  final String title;
  final String iconAsset;
  final Widget child;
  final Color? iconColor;

  const VenueExpandableSection({
    super.key,
    required this.title,
    required this.iconAsset,
    required this.child,
    this.iconColor,
  });

  @override
  State<VenueExpandableSection> createState() => _VenueExpandableSectionState();
}

class _VenueExpandableSectionState extends State<VenueExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubSectionHeader(
          title: widget.title,
          prefixIcon: widget.iconAsset,
          iconColor: widget.iconColor,
          trailingWidget: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: AppColors.greyBorder,
            size: 24,
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: widget.child,
          ),
      ],
    );
  }
}
