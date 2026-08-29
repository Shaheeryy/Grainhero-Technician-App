import 'package:flutter/foundation.dart';

enum GrainNotificationCategory {
  environment,
  device,
  maintenance,
  batch,
  system,
}

enum GrainNotificationSeverity { critical, warning, info, success }

@immutable
class GrainNotification {
  const GrainNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.sourceLabel,
    required this.occurredAt,
    required this.category,
    required this.severity,
    this.requiresAcknowledgement = false,
    this.isRead = false,
    this.isAcknowledged = false,
    this.isDismissed = false,
  });

  final String id;
  final String title;
  final String message;
  final String sourceLabel;
  final DateTime occurredAt;
  final GrainNotificationCategory category;
  final GrainNotificationSeverity severity;
  final bool requiresAcknowledgement;
  final bool isRead;
  final bool isAcknowledged;
  final bool isDismissed;

  bool get isActiveAlert =>
      requiresAcknowledgement && !isAcknowledged && !isDismissed;

  GrainNotification copyWith({
    bool? isRead,
    bool? isAcknowledged,
    bool? isDismissed,
  }) {
    return GrainNotification(
      id: id,
      title: title,
      message: message,
      sourceLabel: sourceLabel,
      occurredAt: occurredAt,
      category: category,
      severity: severity,
      requiresAcknowledgement: requiresAcknowledgement,
      isRead: isRead ?? this.isRead,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

/// In-memory notification source for the current prototype.
///
/// Keeping the mutations behind this class gives the home dashboard and the
/// notification centre one source of truth, while leaving a clean seam for a
/// repository or push-notification stream later.
class NotificationCenter extends ChangeNotifier {
  NotificationCenter({
    List<GrainNotification>? initialNotifications,
    DateTime Function()? now,
    this.refreshDelay = const Duration(milliseconds: 650),
  }) : _now = now ?? DateTime.now {
    _notifications = List<GrainNotification>.of(
      initialNotifications ?? _seedNotifications(_now()),
    );
  }

  final DateTime Function() _now;
  final Duration refreshDelay;
  late List<GrainNotification> _notifications;
  bool _isRefreshing = false;
  bool _isDisposed = false;
  DateTime? _lastSyncedAt;

  List<GrainNotification> get notifications {
    final List<GrainNotification> result =
        _notifications
            .where((item) => !item.isDismissed)
            .toList(growable: false)
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List<GrainNotification>.unmodifiable(result);
  }

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  int get activeAlertCount =>
      notifications.where((item) => item.isActiveAlert).length;

  bool get isRefreshing => _isRefreshing;

  DateTime? get lastSyncedAt => _lastSyncedAt;

  GrainNotification? get highestPriorityActiveAlert {
    final List<GrainNotification> active =
        notifications
            .where((item) => item.isActiveAlert)
            .toList(growable: false)
          ..sort((a, b) {
            final int severity = _severityRank(
              b.severity,
            ).compareTo(_severityRank(a.severity));
            return severity != 0
                ? severity
                : b.occurredAt.compareTo(a.occurredAt);
          });
    return active.isEmpty ? null : active.first;
  }

  void markRead(String id) =>
      _update(id, (item) => item.isRead ? item : item.copyWith(isRead: true));

  void markAllRead() {
    bool changed = false;
    _notifications = _notifications
        .map((item) {
          if (item.isDismissed || item.isRead) return item;
          changed = true;
          return item.copyWith(isRead: true);
        })
        .toList(growable: false);
    if (changed) notifyListeners();
  }

  void acknowledge(String id) => _update(id, (item) {
    if (!item.requiresAcknowledgement || item.isAcknowledged) return item;
    return item.copyWith(isRead: true, isAcknowledged: true);
  });

  /// Removes an inbox item. Unresolved operational alerts must be acknowledged
  /// before they can be dismissed.
  bool dismiss(String id) {
    final GrainNotification? item = _find(id);
    if (item == null || item.isActiveAlert) return false;
    _update(id, (current) => current.copyWith(isDismissed: true));
    return true;
  }

  void restore(String id) =>
      _update(id, (item) => item.copyWith(isDismissed: false));

  /// Adds a newly received notification or replaces a matching one without
  /// duplicating it.
  void upsertIncoming(GrainNotification notification) {
    final int index = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index == -1) {
      _notifications = [notification, ..._notifications];
    } else {
      final List<GrainNotification> updated = List.of(_notifications);
      updated[index] = notification;
      _notifications = updated;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    await Future<void>.delayed(refreshDelay);
    if (_isDisposed) return;
    _lastSyncedAt = _now();
    _isRefreshing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _update(
    String id,
    GrainNotification Function(GrainNotification item) transform,
  ) {
    final int index = _notifications.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final GrainNotification current = _notifications[index];
    final GrainNotification next = transform(current);
    if (identical(current, next)) return;
    final List<GrainNotification> updated = List.of(_notifications);
    updated[index] = next;
    _notifications = updated;
    notifyListeners();
  }

  GrainNotification? _find(String id) {
    for (final GrainNotification item in _notifications) {
      if (item.id == id) return item;
    }
    return null;
  }

  static int _severityRank(GrainNotificationSeverity severity) =>
      switch (severity) {
        GrainNotificationSeverity.critical => 4,
        GrainNotificationSeverity.warning => 3,
        GrainNotificationSeverity.info => 2,
        GrainNotificationSeverity.success => 1,
      };

  static List<GrainNotification> _seedNotifications(DateTime now) => [
    GrainNotification(
      id: 'temperature-critical-silo-2',
      title: 'Temperature above safe range',
      message:
          'Silo 2 reached 34.8°C. Inspect ventilation and grain condition '
          'before the next reading cycle.',
      sourceLabel: 'ESP32 Silo · Silo 2 · 004B12387763',
      occurredAt: now.subtract(const Duration(minutes: 8)),
      category: GrainNotificationCategory.environment,
      severity: GrainNotificationSeverity.critical,
      requiresAcknowledgement: true,
    ),
    GrainNotification(
      id: 'maintenance-warning-silo-1',
      title: 'Maintenance due soon',
      message:
          'The auxiliary humidity sensor is approaching its inspection '
          'interval. Schedule a check within 24 hours.',
      sourceLabel: 'ESP32 Silo Auxiliary · Silo 1 · 004B12387762',
      occurredAt: now.subtract(const Duration(minutes: 42)),
      category: GrainNotificationCategory.maintenance,
      severity: GrainNotificationSeverity.warning,
      requiresAcknowledgement: true,
    ),
    GrainNotification(
      id: 'maintenance-complete-gh-sn-204',
      title: 'Maintenance completed',
      message:
          'Filter replacement, visual inspection, and device testing were '
          'logged successfully.',
      sourceLabel: 'Sensor GH-SN-204',
      occurredAt: now.subtract(const Duration(hours: 3, minutes: 18)),
      category: GrainNotificationCategory.maintenance,
      severity: GrainNotificationSeverity.success,
      isRead: true,
    ),
    GrainNotification(
      id: 'batch-rice-registered',
      title: 'Batch registered',
      message: 'A 5 kg rice batch is now linked to Silo 1 and ready to track.',
      sourceLabel: 'Batch GH-BT-4092 · Silo 1',
      occurredAt: now.subtract(const Duration(days: 1, hours: 2)),
      category: GrainNotificationCategory.batch,
      severity: GrainNotificationSeverity.info,
      isRead: true,
    ),
  ];
}
