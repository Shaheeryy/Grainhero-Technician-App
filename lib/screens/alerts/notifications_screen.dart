import 'package:flutter/material.dart';
import '../../config/grainhero_colors.dart';
import '../../services/notification_center.dart';

enum _NotificationFilter { all, alerts, maintenance, system }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.notificationCenter});

  final NotificationCenter notificationCenter;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;
  bool _unreadOnly = false;
  late Set<String> _knownNotificationIds;
  final Set<String> _recentlyAcknowledgedIds = <String>{};

  NotificationCenter get _center => widget.notificationCenter;

  @override
  void initState() {
    super.initState();
    _knownNotificationIds = _center.notifications
        .map((item) => item.id)
        .toSet();
  }

  @override
  void didUpdateWidget(NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notificationCenter != widget.notificationCenter) {
      _knownNotificationIds = _center.notifications
          .map((item) => item.id)
          .toSet();
    }
  }

  List<GrainNotification> _filteredNotifications(
    List<GrainNotification> items,
  ) {
    return items
        .where((item) {
          final bool matchesCategory = switch (_filter) {
            _NotificationFilter.all => true,
            _NotificationFilter.alerts => item.requiresAcknowledgement,
            _NotificationFilter.maintenance =>
              item.category == GrainNotificationCategory.maintenance,
            _NotificationFilter.system =>
              item.category == GrainNotificationCategory.system ||
                  item.category == GrainNotificationCategory.device ||
                  item.category == GrainNotificationCategory.batch,
          };
          return matchesCategory && (!_unreadOnly || !item.isRead);
        })
        .toList(growable: false);
  }

  int _countFor(_NotificationFilter filter) {
    return switch (filter) {
      _NotificationFilter.all => _center.notifications.length,
      _NotificationFilter.alerts =>
        _center.notifications
            .where((item) => item.requiresAcknowledgement)
            .length,
      _NotificationFilter.maintenance =>
        _center.notifications
            .where(
              (item) => item.category == GrainNotificationCategory.maintenance,
            )
            .length,
      _NotificationFilter.system =>
        _center.notifications
            .where(
              (item) =>
                  item.category == GrainNotificationCategory.system ||
                  item.category == GrainNotificationCategory.device ||
                  item.category == GrainNotificationCategory.batch,
            )
            .length,
    };
  }

  Future<void> _refresh() async {
    await _center.refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Notifications are up to date'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  void _dismiss(GrainNotification notification) {
    if (!_center.dismiss(notification.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Acknowledge this alert before dismissing it.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('“${notification.title}” dismissed'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _center.restore(notification.id),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  void _openDetails(GrainNotification notification) {
    _center.markRead(notification.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _NotificationDetailsSheet(
        notification: notification,
        onAcknowledge: notification.isActiveAlert
            ? () {
                _acknowledge(notification.id);
                Navigator.of(sheetContext).pop();
              }
            : null,
      ),
    );
  }

  void _acknowledge(String id) {
    setState(() => _recentlyAcknowledgedIds.add(id));
    _center.acknowledge(id);
  }

  void _finishAcknowledgementFeedback(String id) {
    if (!mounted || !_recentlyAcknowledgedIds.contains(id)) return;
    setState(() => _recentlyAcknowledgedIds.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrainHeroColors.pageBackground,
      body: AnimatedBuilder(
        animation: _center,
        builder: (context, _) {
          final List<GrainNotification> all = _center.notifications;
          final List<GrainNotification> visible = _filteredNotifications(all);
          final Set<String> currentIds = all.map((item) => item.id).toSet();
          final Set<String> incomingIds = currentIds.difference(
            _knownNotificationIds,
          );
          _knownNotificationIds.addAll(currentIds);

          return Column(
            children: [
              _NotificationsHeader(
                isRefreshing: _center.isRefreshing,
                onBack: () => Navigator.of(context).maybePop(),
                onRefresh: _refresh,
                onMarkAllRead: _center.unreadCount == 0
                    ? null
                    : _center.markAllRead,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: GrainHeroColors.primary,
                  backgroundColor: GrainHeroColors.surface,
                  onRefresh: _refresh,
                  child: ListView(
                    key: const ValueKey('notifications-list'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                    children: [
                      _NotificationsOverview(
                        activeAlertCount: _center.activeAlertCount,
                        unreadCount: _center.unreadCount,
                      ),
                      const SizedBox(height: 16),
                      _NotificationFilters(
                        selected: _filter,
                        unreadOnly: _unreadOnly,
                        unreadCount: _center.unreadCount,
                        countFor: _countFor,
                        onSelected: (filter) {
                          if (_filter == filter) return;
                          setState(() => _filter = filter);
                        },
                        onUnreadOnlyChanged: (value) {
                          if (_unreadOnly == value) return;
                          setState(() => _unreadOnly = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      if (visible.isEmpty)
                        _EmptyNotificationState(
                          filter: _filter,
                          unreadOnly: _unreadOnly,
                          isInboxEmpty: all.isEmpty,
                          onRefresh: _refresh,
                          onShowAll: () => setState(() {
                            _filter = _NotificationFilter.all;
                            _unreadOnly = false;
                          }),
                        )
                      else
                        _NotificationGroups(
                          notifications: visible,
                          animateIds: incomingIds,
                          recentlyAcknowledgedIds: _recentlyAcknowledgedIds,
                          onTap: _openDetails,
                          onAcknowledge: _acknowledge,
                          onAcknowledgementFeedbackFinished:
                              _finishAcknowledgementFeedback,
                          onDismiss: _dismiss,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationsOverview extends StatelessWidget {
  const _NotificationsOverview({
    required this.activeAlertCount,
    required this.unreadCount,
  });

  final int activeAlertCount;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('notifications-overview'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: GrainHeroColors.brandDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                activeAlertCount == 0
                    ? 'All systems steady'
                    : 'Attention needed',
                style: TextStyle(
                  color: activeAlertCount == 0
                      ? GrainHeroColors.primary
                      : GrainHeroColors.warningBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  key: const ValueKey('notifications-overview-alerts'),
                  icon: activeAlertCount == 0
                      ? Icons.check_circle_outline_rounded
                      : Icons.notifications_active_outlined,
                  iconColor: activeAlertCount == 0
                      ? GrainHeroColors.primary
                      : GrainHeroColors.warningBright,
                  value: '$activeAlertCount',
                  label: activeAlertCount == 1
                      ? 'Active alert'
                      : 'Active alerts',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withValues(alpha: 0.16),
              ),
              Expanded(
                child: _OverviewMetric(
                  key: const ValueKey('notifications-overview-unread'),
                  icon: unreadCount == 0
                      ? Icons.drafts_outlined
                      : Icons.mark_email_unread_outlined,
                  iconColor: GrainHeroColors.primary,
                  value: '$unreadCount',
                  label: 'Unread',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 27),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GrainHeroColors.onDarkMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.isRefreshing,
    required this.onBack,
    required this.onRefresh,
    required this.onMarkAllRead,
  });

  final bool isRefreshing;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, -18 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        key: const ValueKey('notifications-header'),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 18),
        decoration: const BoxDecoration(
          color: GrainHeroColors.brandDark,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Row(
          key: const ValueKey('notifications-header-title-row'),
          children: [
            IconButton(
              key: const ValueKey('notifications-back-button'),
              onPressed: onBack,
              tooltip: 'Back',
              style: IconButton.styleFrom(
                fixedSize: const Size(44, 44),
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Notifications',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.45,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              key: const ValueKey('notifications-refresh-button'),
              onPressed: isRefreshing ? null : onRefresh,
              tooltip: 'Refresh notifications',
              style: IconButton.styleFrom(
                fixedSize: const Size(44, 44),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                backgroundColor: Colors.white.withValues(alpha: 0.09),
                shape: const CircleBorder(),
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isRefreshing
                    ? const SizedBox(
                        key: ValueKey('refresh-progress'),
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        key: ValueKey('refresh-icon'),
                      ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              key: const ValueKey('mark-all-read-button'),
              onPressed: onMarkAllRead,
              tooltip: 'Mark all as read',
              style: IconButton.styleFrom(
                fixedSize: const Size(44, 44),
                foregroundColor: Colors.white,
                disabledForegroundColor: GrainHeroColors.onDarkMuted,
                backgroundColor: Colors.white.withValues(alpha: 0.09),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 21),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({
    required this.selected,
    required this.unreadOnly,
    required this.unreadCount,
    required this.countFor,
    required this.onSelected,
    required this.onUnreadOnlyChanged,
  });

  final _NotificationFilter selected;
  final bool unreadOnly;
  final int unreadCount;
  final int Function(_NotificationFilter filter) countFor;
  final ValueChanged<_NotificationFilter> onSelected;
  final ValueChanged<bool> onUnreadOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final _NotificationFilter filter
              in _NotificationFilter.values) ...[
            FilterChip(
              key: ValueKey('notification-filter-${filter.name}'),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              label: Text('${_filterLabel(filter)} · ${countFor(filter)}'),
              labelStyle: TextStyle(
                color: filter == selected
                    ? GrainHeroColors.surface
                    : GrainHeroColors.primaryDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(
                color: filter == selected
                    ? GrainHeroColors.brandDark
                    : GrainHeroColors.primaryDark.withValues(alpha: 0.45),
              ),
              backgroundColor: GrainHeroColors.surface,
              selectedColor: GrainHeroColors.brandDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 8),
            if (filter == _NotificationFilter.all) ...[
              FilterChip(
                key: const ValueKey('notification-unread-only'),
                selected: unreadOnly,
                onSelected: onUnreadOnlyChanged,
                showCheckmark: false,
                label: Text('Unread only · $unreadCount'),
                labelStyle: TextStyle(
                  color: unreadOnly
                      ? GrainHeroColors.surface
                      : GrainHeroColors.primaryDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: unreadOnly
                      ? GrainHeroColors.brandDark
                      : GrainHeroColors.primaryDark.withValues(alpha: 0.45),
                ),
                backgroundColor: GrainHeroColors.surface,
                selectedColor: GrainHeroColors.brandDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: GrainHeroColors.outline,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ],
      ),
    );
  }

  static String _filterLabel(_NotificationFilter filter) => switch (filter) {
    _NotificationFilter.all => 'All',
    _NotificationFilter.alerts => 'Alerts',
    _NotificationFilter.maintenance => 'Maintenance',
    _NotificationFilter.system => 'System',
  };
}

class _NotificationGroups extends StatelessWidget {
  const _NotificationGroups({
    required this.notifications,
    required this.animateIds,
    required this.recentlyAcknowledgedIds,
    required this.onTap,
    required this.onAcknowledge,
    required this.onAcknowledgementFeedbackFinished,
    required this.onDismiss,
  });

  final List<GrainNotification> notifications;
  final Set<String> animateIds;
  final Set<String> recentlyAcknowledgedIds;
  final ValueChanged<GrainNotification> onTap;
  final ValueChanged<String> onAcknowledge;
  final ValueChanged<String> onAcknowledgementFeedbackFinished;
  final ValueChanged<GrainNotification> onDismiss;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    String? currentGroup;
    for (final GrainNotification notification in notifications) {
      final String group = _dayGroup(notification.occurredAt);
      if (group != currentGroup) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 22));
        children.add(_GroupHeading(label: group));
        children.add(const SizedBox(height: 10));
        currentGroup = group;
      } else {
        children.add(const SizedBox(height: 10));
      }
      final Widget dismissible = Dismissible(
        key: ValueKey('dismiss-${notification.id}'),
        direction: notification.isActiveAlert
            ? DismissDirection.none
            : DismissDirection.endToStart,
        confirmDismiss: (_) async {
          return !notification.isActiveAlert;
        },
        onDismissed: (_) => onDismiss(notification),
        background: const _DismissBackground(),
        child: _NotificationCard(
          notification: notification,
          onTap: () => onTap(notification),
          showAcknowledgementFeedback: recentlyAcknowledgedIds.contains(
            notification.id,
          ),
          onAcknowledgementFeedbackFinished: () =>
              onAcknowledgementFeedbackFinished(notification.id),
          onAcknowledge: notification.isActiveAlert
              ? () => onAcknowledge(notification.id)
              : null,
        ),
      );
      children.add(
        _IncomingNotificationEntrance(
          animate: animateIds.contains(notification.id),
          child: dismissible,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  static String _dayGroup(DateTime timestamp) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );
    final int difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${_monthName(timestamp.month)} ${timestamp.day}';
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: GrainHeroColors.outline, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: GrainHeroColors.primaryDark,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: GrainHeroColors.mainText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingNotificationEntrance extends StatelessWidget {
  const _IncomingNotificationEntrance({
    required this.animate,
    required this.child,
  });

  final bool animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animate || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 14 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onAcknowledge,
    required this.showAcknowledgementFeedback,
    required this.onAcknowledgementFeedbackFinished,
  });

  final GrainNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onAcknowledge;
  final bool showAcknowledgementFeedback;
  final VoidCallback onAcknowledgementFeedbackFinished;

  @override
  Widget build(BuildContext context) {
    final Color severityColor = _severityColor(notification.severity);
    return Semantics(
      button: true,
      label:
          '${notification.isRead ? '' : 'Unread, '}${notification.title}. '
          '${notification.message}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: GrainHeroColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: notification.isRead
                ? GrainHeroColors.outline.withValues(alpha: 0.48)
                : GrainHeroColors.outline.withValues(alpha: 0.90),
            width: notification.isRead ? 1 : 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('notification-card-${notification.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SeverityIcon(severity: notification.severity),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      color: GrainHeroColors.mainText,
                                      fontSize: 16,
                                      height: 1.3,
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: notification.isRead ? 0 : 1,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    margin: const EdgeInsets.only(top: 5),
                                    decoration: BoxDecoration(
                                      color: severityColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _relativeTime(notification.occurredAt),
                              style: const TextStyle(
                                color: GrainHeroColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GrainHeroColors.mainText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        color: GrainHeroColors.mutedText,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          notification.sourceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: GrainHeroColors.mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (onAcknowledge != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        key: ValueKey(
                          'acknowledge-notification-${notification.id}',
                        ),
                        onPressed: onAcknowledge,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          foregroundColor: Colors.white,
                          backgroundColor: GrainHeroColors.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Acknowledge'),
                      ),
                    ),
                  ] else if (showAcknowledgementFeedback) ...[
                    _AcknowledgementFeedback(
                      onFinished: onAcknowledgementFeedbackFinished,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: GrainHeroColors.brandDark,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white),
          SizedBox(height: 3),
          Text(
            'Dismiss',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcknowledgementFeedback extends StatefulWidget {
  const _AcknowledgementFeedback({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_AcknowledgementFeedback> createState() =>
      _AcknowledgementFeedbackState();
}

class _AcknowledgementFeedbackState extends State<_AcknowledgementFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 420),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0.16),
      end: Offset.zero,
    ).animate(_curvedAnimation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runSequence();
    });
  }

  Future<void> _runSequence() async {
    await _controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizeTransition(
        sizeFactor: _curvedAnimation,
        alignment: Alignment.topRight,
        child: FadeTransition(
          opacity: _curvedAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: GrainHeroColors.primaryDark,
                    size: 17,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Acknowledged',
                    style: TextStyle(
                      color: GrainHeroColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState({
    required this.filter,
    required this.unreadOnly,
    required this.isInboxEmpty,
    required this.onRefresh,
    required this.onShowAll,
  });

  final _NotificationFilter filter;
  final bool unreadOnly;
  final bool isInboxEmpty;
  final VoidCallback onRefresh;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final String title = unreadOnly && !isInboxEmpty
        ? 'No unread notifications'
        : isInboxEmpty || filter == _NotificationFilter.alerts
        ? 'No Active Alerts'
        : switch (filter) {
            _NotificationFilter.maintenance => 'No maintenance updates',
            _NotificationFilter.system => 'No system updates',
            _NotificationFilter.all => 'No notifications yet',
            _NotificationFilter.alerts => 'No Active Alerts',
          };
    final String message = isInboxEmpty || filter == _NotificationFilter.alerts
        ? 'Everything is running smoothly! We’ll keep watching your connected silos.'
        : 'There’s nothing in this view right now. Your other updates are still available.';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 390),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: GrainHeroColors.surface,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: GrainHeroColors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: GrainHeroColors.brandDark.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: GrainHeroColors.mainText,
                  size: 44,
                ),
              ),
              Positioned(
                right: -5,
                bottom: -5,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GrainHeroColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GrainHeroColors.pageBackground,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GrainHeroColors.mainText,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GrainHeroColors.mutedText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (isInboxEmpty)
            FilledButton.icon(
              key: const ValueKey('empty-notifications-retry'),
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                backgroundColor: GrainHeroColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(138, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text('Check again'),
            )
          else
            OutlinedButton.icon(
              key: const ValueKey('show-all-notifications'),
              onPressed: onShowAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: GrainHeroColors.primaryDark,
                minimumSize: const Size(138, 50),
                side: const BorderSide(color: GrainHeroColors.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.inbox_rounded, size: 18),
              label: const Text('Show all'),
            ),
        ],
      ),
    );
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  const _NotificationDetailsSheet({
    required this.notification,
    required this.onAcknowledge,
  });

  final GrainNotification notification;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        10,
        22,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: GrainHeroColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: GrainHeroColors.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SeverityIcon(severity: notification.severity, large: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SeverityLabel(severity: notification.severity),
                      const SizedBox(height: 8),
                      Text(
                        notification.title,
                        style: const TextStyle(
                          color: GrainHeroColors.mainText,
                          fontSize: 23,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              notification.message,
              style: const TextStyle(
                color: GrainHeroColors.mainText,
                fontSize: 15,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            _DetailRow(
              icon: Icons.sensors_rounded,
              label: 'Source',
              value: notification.sourceLabel,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Received',
              value:
                  '${_relativeTime(notification.occurredAt)} · '
                  '${_twoDigits(notification.occurredAt.hour)}:'
                  '${_twoDigits(notification.occurredAt.minute)}',
            ),
            if (onAcknowledge != null) ...[
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('details-acknowledge-button'),
                  onPressed: onAcknowledge,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: GrainHeroColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Acknowledge alert'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GrainHeroColors.tonedEggshell,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: GrainHeroColors.primaryDark, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: GrainHeroColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: GrainHeroColors.mainText,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _SeverityIcon extends StatelessWidget {
  const _SeverityIcon({required this.severity, this.large = false});

  final GrainNotificationSeverity severity;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: large ? 58 : 44,
      height: large ? 58 : 44,
      child: Icon(
        _severityIcon(severity),
        color: _severityIconColor(severity),
        size: large ? 40 : 31,
      ),
    );
  }
}

class _SeverityLabel extends StatelessWidget {
  const _SeverityLabel({required this.severity});

  final GrainNotificationSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Text(
      _severityLabel(severity),
      style: TextStyle(
        color: _severityColor(severity),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

Color _severityColor(GrainNotificationSeverity severity) => switch (severity) {
  GrainNotificationSeverity.critical => GrainHeroColors.error,
  GrainNotificationSeverity.warning => GrainHeroColors.warning,
  GrainNotificationSeverity.info => GrainHeroColors.info,
  GrainNotificationSeverity.success => GrainHeroColors.primaryDark,
};

Color _severityIconColor(GrainNotificationSeverity severity) =>
    severity == GrainNotificationSeverity.critical
    ? GrainHeroColors.error
    : GrainHeroColors.primaryDark;

IconData _severityIcon(GrainNotificationSeverity severity) =>
    switch (severity) {
      GrainNotificationSeverity.critical => Icons.device_thermostat_rounded,
      GrainNotificationSeverity.warning => Icons.build_circle_rounded,
      GrainNotificationSeverity.info => Icons.inventory_2_rounded,
      GrainNotificationSeverity.success => Icons.task_alt_rounded,
    };

String _severityLabel(GrainNotificationSeverity severity) => switch (severity) {
  GrainNotificationSeverity.critical => 'Critical',
  GrainNotificationSeverity.warning => 'Warning',
  GrainNotificationSeverity.info => 'Info',
  GrainNotificationSeverity.success => 'Completed',
};

String _relativeTime(DateTime timestamp) {
  final Duration difference = DateTime.now().difference(timestamp);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} hr ago';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}

String _monthName(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

String _twoDigits(int value) => value.toString().padLeft(2, '0');
