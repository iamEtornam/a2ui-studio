import 'package:flutter/material.dart';
import '../../../domain/models/mini_app.dart';
import '../../features/studio/studio_view_model.dart';
import '../a2ui/a2ui_surface_host.dart';
import '../theme/studio_colors.dart';

/// Launches and runs a saved or installed A2UI mini app interactively.
class MiniAppRunnerDialog extends StatelessWidget {
  const MiniAppRunnerDialog({
    super.key,
    required this.miniApp,
    required this.viewModel,
  });

  final MiniApp miniApp;
  final StudioViewModel viewModel;

  static Future<void> show(
    BuildContext context,
    MiniApp app,
    StudioViewModel viewModel,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => MiniAppRunnerDialog(miniApp: app, viewModel: viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width < 600 ? size.width - 24 : 520.0;
    final maxHeight = size.height * 0.86;

    return Dialog(
      backgroundColor: c.canvasBg,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.borderStrong),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.panelBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(bottom: BorderSide(color: c.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: miniApp.isPublic
                          ? c.publicBadgeBg
                          : c.privateBadgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      miniApp.visibility.badgeLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: miniApp.isPublic
                            ? c.publicBadgeFg
                            : c.privateBadgeFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      miniApp.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      viewModel.forkMiniAppToChat(miniApp);
                    },
                    icon: const Icon(Icons.call_split_rounded, size: 15),
                    label: const Text('Fork & Edit'),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: A2uiSurfaceHost(
                messages: miniApp.a2uiMessages,
                onNotify: viewModel.triggerLocalNotification,
                onTelemetry: viewModel.addTelemetry,
                onMiniChat: viewModel.sendMiniAppChat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
