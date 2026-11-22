import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Represents a local notification event triggered by a mini app or simulator.
class StudioNotificationEvent {
  const StudioNotificationEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.channelId,
    required this.timestamp,
    this.appName = 'A2UI Studio',
    this.isScheduled = false,
  });

  final String id;
  final String title;
  final String body;
  final String channelId;
  final DateTime timestamp;
  final String appName;
  final bool isScheduled;
}

/// Cross-platform local notification service supporting Mobile, Web, and Desktop.
///
/// Surfaces live interactive OS-style notification banners inside the studio
/// and tracks active scheduled reminders & telemetry logs.
class LocalNotificationService extends ChangeNotifier {
  final _uuid = const Uuid();
  final List<StudioNotificationEvent> _history = [];
  final List<StudioNotificationEvent> _scheduled = [];
  StudioNotificationEvent? _activeBanner;
  Timer? _dismissTimer;

  List<StudioNotificationEvent> get history => List.unmodifiable(_history);
  List<StudioNotificationEvent> get scheduled => List.unmodifiable(_scheduled);
  StudioNotificationEvent? get activeBanner => _activeBanner;
  int get activeScheduledCount => _scheduled.length;

  /// Triggers an immediate local notification banner and records it in history.
  StudioNotificationEvent triggerNotification({
    required String title,
    required String body,
    String channelId = 'a2ui_task_reminders',
    String appName = 'TaskPulse',
  }) {
    final event = StudioNotificationEvent(
      id: _uuid.v4(),
      title: title,
      body: body,
      channelId: channelId,
      timestamp: DateTime.now(),
      appName: appName,
    );
    _history.insert(0, event);
    _activeBanner = event;
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), dismissBanner);
    notifyListeners();
    return event;
  }

  /// Registers a scheduled local reminder (and optionally fires a confirmation).
  StudioNotificationEvent scheduleReminder({
    required String title,
    required String body,
    String channelId = 'a2ui_task_reminders',
    String appName = 'TaskPulse',
    Duration delay = const Duration(seconds: 4),
  }) {
    final event = StudioNotificationEvent(
      id: _uuid.v4(),
      title: title,
      body: body,
      channelId: channelId,
      timestamp: DateTime.now().add(delay),
      appName: appName,
      isScheduled: true,
    );
    _scheduled.insert(0, event);
    notifyListeners();

    Timer(delay, () {
      triggerNotification(
        title: title,
        body: body,
        channelId: channelId,
        appName: appName,
      );
    });
    return event;
  }

  void dismissBanner() {
    if (_activeBanner == null) return;
    _activeBanner = null;
    _dismissTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
