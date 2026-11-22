import 'package:flutter/material.dart';
import '../../../data/services/local_notification_service.dart';
import '../theme/studio_colors.dart';

/// Displays an interactive OS-style local notification toast across mobile, web, and desktop.
class NotificationToastOverlay extends StatelessWidget {
  const NotificationToastOverlay({
    super.key,
    required this.notificationService,
  });

  final LocalNotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notificationService,
      builder: (context, _) {
        final banner = notificationService.activeBanner;
        if (banner == null) return const SizedBox.shrink();
        final c = StudioColors.of(context);

        return Positioned(
          top: 16,
          right: 16,
          left: MediaQuery.sizeOf(context).width < 520 ? 16 : null,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.panelBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: c.cyanAccent.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c.cyanAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: c.cyanAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    banner.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  'LOCAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: c.cyanAccent,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              banner.body,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${banner.appName} • channel: ${banner.channelId}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: c.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.close, size: 16, color: c.textMuted),
                        onPressed: notificationService.dismissBanner,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
