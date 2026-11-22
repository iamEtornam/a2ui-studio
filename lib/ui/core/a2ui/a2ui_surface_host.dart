import 'dart:convert';
import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/material.dart';
import '../theme/studio_colors.dart';
import 'a2ui_sanitizer.dart';
import 'studio_catalog.dart';

/// Hosts a live `a2ui_flutter` [MessageProcessor] and renders its [A2uiSurface].
class A2uiSurfaceHost extends StatefulWidget {
  const A2uiSurfaceHost({
    super.key,
    required this.messages,
    this.onNotify,
    this.onAction,
    this.onTelemetry,
    this.onMiniChat,
    this.padding = const EdgeInsets.all(12),
    this.scrollable = true,
  });

  final List<Map<String, Object?>> messages;
  final A2uiNotificationCallback? onNotify;
  final ValueChanged<String>? onAction;
  final A2uiTelemetryCallback? onTelemetry;
  final A2uiMiniChatCallback? onMiniChat;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  State<A2uiSurfaceHost> createState() => _A2uiSurfaceHostState();
}

class _A2uiSurfaceHostState extends State<A2uiSurfaceHost> {
  MessageProcessor<ComponentImplementation>? _processor;
  SurfaceModel<ComponentImplementation>? _surface;
  String? _errorText;
  String _lastSignature = '';

  @override
  void initState() {
    super.initState();
    _rebuildProcessor();
  }

  @override
  void didUpdateWidget(covariant A2uiSurfaceHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sig = jsonEncode(widget.messages);
    if (sig != _lastSignature) {
      _rebuildProcessor();
    }
  }

  void _rebuildProcessor() {
    _processor?.dispose();
    _surface = null;
    _errorText = null;
    _lastSignature = jsonEncode(widget.messages);

    final processor = MessageProcessor<ComponentImplementation>(
      catalogs: [
        basicCatalog(),
        StudioCatalog.create(
          onNotify: widget.onNotify,
          onTelemetry: widget.onTelemetry,
          onMiniChat: widget.onMiniChat,
        ),
      ],
    );

    processor.model.onSurfaceCreated.subscribe((created) {
      if (mounted) {
        setState(() => _surface = created);
      }
    });

    processor.model.onAction.subscribe((action) {
      widget.onAction?.call(action.name);
      widget.onTelemetry?.call('[a2ui_flutter] Action: ${action.name}');
      if (action.name.toLowerCase().contains('notif') ||
          action.name.toLowerCase().contains('remind')) {
        widget.onNotify?.call(
          title: 'Mini App Notification',
          body: 'Triggered action "${action.name}" via a2ui_flutter.',
          scheduled: false,
        );
      }
    });

    processor.model.onError.subscribe((err) {
      widget.onTelemetry?.call('[a2ui_core Error] ${err.message}');
    });

    try {
      if (widget.messages.isNotEmpty) {
        processor.processMessages(A2uiSanitizer.sanitize(widget.messages));
      }
    } catch (e) {
      _errorText = e.toString();
      widget.onTelemetry?.call('[a2ui_flutter Parse Error] $e');
    }

    _processor = processor;
  }

  @override
  void dispose() {
    _processor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = StudioColors.of(context);
    if (_errorText != null) {
      return Padding(
        padding: widget.padding,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.danger.withValues(alpha: 0.4)),
          ),
          child: Text(
            'A2UI Surface Error:\n$_errorText',
            style: TextStyle(fontSize: 12, color: c.danger),
          ),
        ),
      );
    }

    final surface = _surface;
    if (surface == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Describe your mini app in chat to generate a live a2ui_flutter surface.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final rendered = Padding(
      padding: widget.padding,
      child: A2uiSurface(key: ObjectKey(surface), surface: surface),
    );

    if (!widget.scrollable) return rendered;
    return SingleChildScrollView(child: rendered);
  }
}
