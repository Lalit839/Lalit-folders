import 'package:activ_user_app/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:activ_user_app/core/storage/shared_pref_service.dart';
import 'package:activ_user_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:activ_user_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:activ_user_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:activ_user_app/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:activ_user_app/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:activ_user_app/features/notifications/presentation/shimmer/notification_shimmer.dart';
import 'package:activ_user_app/features/notifications/presentation/state/notification_state.dart';
import 'package:activ_user_app/features/notifications/presentation/widgets/notification_empty_view.dart';
import 'package:activ_user_app/features/notifications/presentation/widgets/notification_list.dart';
import 'package:activ_user_app/routes/app_routes.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize clean architecture layers manually (Self-contained dependency injection)
    final dataSource = const ApiNotificationRemoteDataSource();
    final repository = NotificationRepositoryImpl(dataSource);

    _controller = NotificationController(
      getNotificationsUseCase: GetNotificationsUseCase(repository),
      markNotificationReadUseCase: MarkNotificationReadUseCase(repository),
      markAllNotificationsReadUseCase: MarkAllNotificationsReadUseCase(
        repository,
      ),
      deleteNotificationUseCase: DeleteNotificationUseCase(repository),
    );

    _controller.fetchNotifications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNotificationTap(NotificationEntity notification) {
    _controller.markAsRead(notification.id);

    final target = notification.targetType?.toLowerCase();
    String? route;
    Map<String, dynamic>? arguments;

    switch (target) {
      case 'booking':
        final bookingId = notification.targetId ?? '';
        if (bookingId.isNotEmpty) {
          route = AppRoutes.bookingDetails;
          arguments = {'bookingId': bookingId};
        } else {
          route = AppRoutes.bookings;
        }
        break;
      case 'offer':
        route = AppRoutes.coupons;
        break;
      default:
        if (notification.type == NotificationType.booking) {
          route = AppRoutes.bookings;
        } else if (notification.type == NotificationType.offer) {
          route = AppRoutes.coupons;
        } else {
          return;
        }
    }

    if (!mounted) return;
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  void _syncUnreadState(List<NotificationEntity> notifications) {
    final hasUnread = notifications.any((e) => !e.isRead);
    if (hasUnread != SharedPrefService.hasUnreadNotifications) {
      SharedPrefService.setHasUnreadNotifications(hasUnread);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NotificationState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        if (!state.isLoading && state.errorMessage == null) {
          _syncUnreadState(state.notifications);
        }

        final hasUnread = state.notifications.any((e) => !e.isRead);

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: const AppHeader(
            title: 'Notifications',
          ),
          body: Builder(builder: (context) {
            if (state.isLoading) {
              return const NotificationShimmer();
            }

            if (state.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state.notifications.isEmpty) {
              return const NotificationEmptyView();
            }

            return NotificationList(
              notifications: state.notifications,
              onRefresh: () => _controller.fetchNotifications(),
              onNotificationTap: _handleNotificationTap,
              onNotificationDelete: (id) => _controller.deleteNotification(id),
            );
          }),
        );
      },
    );
  }
}

