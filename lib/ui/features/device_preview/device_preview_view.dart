import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/a2ui/a2ui_surface_host.dart';
import '../../core/theme/studio_colors.dart';
import '../studio/studio_view_model.dart';

enum _SimLayoutMode { dual, mobileOnly, desktopOnly }

/// Synchronized Multi-Platform Device Preview (Mobile + Desktop/Web) with
/// live local notification testing and A2UI diagnostics console.
class DevicePreviewView extends StatefulWidget {
  const DevicePreviewView({super.key, required this.viewModel});

  final StudioViewModel viewModel;

  @override
  State<DevicePreviewView> createState() => _DevicePreviewViewState();
}

class _DevicePreviewViewState extends State<DevicePreviewView> {
  _SimLayoutMode _layoutMode = _SimLayoutMode.dual;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final c = StudioColors.of(context);
        final vm = widget.viewModel;
        final session = vm.activeSession;
        final messages = session?.currentA2uiMessages ?? const [];

        return Container(
          color: c.canvasBg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Simulator Toolbar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.panelBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c.primaryAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.devices_rounded,
                              color: c.cyanAccent,
                              size: 18,
                            ),
                          ),
                          Text(
                            session?.currentAppTitle ?? 'Mini App Preview',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.privateBadgeBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Testing Mode',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: c.privateBadgeFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Mobile & Desktop'),
                            selected: _layoutMode == _SimLayoutMode.dual,
                            onSelected: (_) =>
                                setState(() => _layoutMode = _SimLayoutMode.dual),
                          ),
                          ChoiceChip(
                            label: const Text('iPhone 16 Pro'),
                            selected: _layoutMode == _SimLayoutMode.mobileOnly,
                            onSelected: (_) => setState(
                              () => _layoutMode = _SimLayoutMode.mobileOnly,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('macOS / Web'),
                            selected: _layoutMode == _SimLayoutMode.desktopOnly,
                            onSelected: (_) => setState(
                              () => _layoutMode = _SimLayoutMode.desktopOnly,
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => vm.triggerLocalNotification(
                              title:
                                  '${session?.currentAppTitle ?? "Mini App"} Alert',
                              body:
                                  'Test local notification fired from Multi-Platform Simulator.',
                            ),
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                            ),
                            label: const Text('Trigger Test Notification'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => vm.triggerLocalNotification(
                              title: 'Scheduled Reminder (4s)',
                              body:
                                  'Your scheduled background task notification arrived!',
                              scheduled: true,
                            ),
                            icon: const Icon(Icons.schedule, size: 16),
                            label: const Text('Schedule 4s Alert'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Synchronized Viewports
                LayoutBuilder(
                  builder: (context, constraints) {
                    final canShowSideBySide =
                        constraints.maxWidth >= 980 &&
                        _layoutMode == _SimLayoutMode.dual;

                    final mobileFrame = _DeviceFrame(
                      title: 'iPhone 16 Pro',
                      meta: '393 x 852 pt • Mobile Viewport',
                      icon: Icons.smartphone_rounded,
                      borderRadius: 34,
                      borderWidth: 5,
                      height: 600,
                      maxWidth: 380,
                      child: A2uiSurfaceHost(
                        messages: messages,
                        onNotify: vm.triggerLocalNotification,
                        onTelemetry: vm.addTelemetry,
                        onMiniChat: vm.sendMiniAppChat,
                      ),
                    );

                    final desktopFrame = _DeviceFrame(
                      title: 'macOS / Web Canvas',
                      meta: 'Responsive Breakpoint: XL • Impeller / Web',
                      icon: Icons.laptop_mac_rounded,
                      borderRadius: 14,
                      borderWidth: 1.5,
                      height: 600,
                      maxWidth: double.infinity,
                      child: A2uiSurfaceHost(
                        messages: messages,
                        onNotify: vm.triggerLocalNotification,
                        onTelemetry: vm.addTelemetry,
                        onMiniChat: vm.sendMiniAppChat,
                      ),
                    );

                    if (_layoutMode == _SimLayoutMode.mobileOnly) {
                      return Center(child: mobileFrame);
                    }
                    if (_layoutMode == _SimLayoutMode.desktopOnly) {
                      return desktopFrame;
                    }
                    if (canShowSideBySide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          mobileFrame,
                          const SizedBox(width: 20),
                          Expanded(child: desktopFrame),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Center(child: mobileFrame),
                        const SizedBox(height: 20),
                        desktopFrame,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Telemetry & Diagnostics Console
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.codeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.terminal_rounded,
                            size: 16,
                            color: c.cyanAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Telemetry & Diagnostics',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${vm.telemetryLogs.length} events',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: vm.telemetryLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                vm.telemetryLogs[index],
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11.5,
                                  color: index == 0
                                      ? c.cyanAccent
                                      : c.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({
    required this.title,
    required this.meta,
    required this.icon,
    required this.borderRadius,
    required this.borderWidth,
    required this.height,
    required this.maxWidth,
    required this.child,
  });

  final String title;
  final String meta;
  final IconData icon;
  final double borderRadius;
  final double borderWidth;
  final double height;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: c.cyanAccent),
              const SizedBox(width: 6),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                meta,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10.5,
                  color: c.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.panelBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: c.borderStrong, width: borderWidth),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }
}
