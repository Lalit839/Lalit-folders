import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/constants/app_colors.dart';
import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:activ_user_app/features/notifications/presentation/widgets/notification_card.dart';

class NotificationList extends StatefulWidget {
  final List<NotificationEntity> notifications;
  final Future<void> Function() onRefresh;
  final Function(NotificationEntity) onNotificationTap;
  final Function(String) onNotificationDelete;
  final bool isLoadingMore;
  final Future<void> Function()? onLoadMore;

  const NotificationList({
    super.key,
    required this.notifications,
    required this.onRefresh,
    required this.onNotificationTap,
    required this.onNotificationDelete,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoadingMore && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      backgroundColor: const Color(0xFF1E1E1E),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: widget.notifications.length + (widget.isLoadingMore ? 1 : 0),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        separatorBuilder: (context, index) => AppDivider(verticalPadding: 0),
        itemBuilder: (context, index) {
          if (index == widget.notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final notification = widget.notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () => widget.onNotificationTap(notification),
            onDelete: () => widget.onNotificationDelete(notification.id),
          );
        },
      ),
    );
  }
}
