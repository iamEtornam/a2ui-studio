import 'package:a2ui_core/a2ui_core.dart';
import 'studio_catalog.dart';

/// Sanitizes LLM-generated A2UI v1.0 message envelopes so strict `a2ui_core`
/// validation never fails on extra/hallucinated envelope fields (e.g. `darkTheme`)
/// or missing `catalogId` on custom StudioCatalog components.
class A2uiSanitizer {
  static const int maxMessages = 20;
  static const int maxComponentsPerSurface = 60;

  static const _allowedCreateSurfaceKeys = {
    'surfaceId',
    'catalogId',
    'sendDataModel',
    'components',
    'dataModel',
    'metadata',
  };

  static const _allowedUpdateComponentsKeys = {
    'surfaceId',
    'components',
  };

  static const _allowedUpdateDataModelKeys = {
    'surfaceId',
    'path',
    'value',
  };

  static const _studioComponentNames = {
    'MiniAppHeader',
    'CalendarWidget',
    'TodoBoard',
    'MiniChatPanel',
    'LocalNotificationCard',
    'MetricChartCard',
    'PomodoroTimer',
    'HabitHeatmap',
  };

  static List<Map<String, Object?>> sanitize(
    List<Map<String, Object?>> messages,
  ) {
    final cleaned = <Map<String, Object?>>[];
    for (final raw in messages.take(maxMessages)) {
      final msg = Map<String, Object?>.from(raw);
      msg['version'] = '1.0';

      if (msg['createSurface'] is Map) {
        final src = Map<String, Object?>.from(msg['createSurface']! as Map);
        final filtered = <String, Object?>{
          for (final entry in src.entries)
            if (_allowedCreateSurfaceKeys.contains(entry.key))
              entry.key: entry.value,
        };
        filtered.putIfAbsent('catalogId', () => BasicCatalog.v1_0Id);
        if (filtered['components'] is List) {
          filtered['components'] = _sanitizeComponents(
            filtered['components']! as List,
          );
        }
        msg['createSurface'] = filtered;
        cleaned.add({
          'version': '1.0',
          'createSurface': filtered,
        });
        continue;
      }

      if (msg['updateComponents'] is Map) {
        final src = Map<String, Object?>.from(msg['updateComponents']! as Map);
        final filtered = <String, Object?>{
          for (final entry in src.entries)
            if (_allowedUpdateComponentsKeys.contains(entry.key))
              entry.key: entry.value,
        };
        if (filtered['components'] is List) {
          filtered['components'] = _sanitizeComponents(
            filtered['components']! as List,
          );
        }
        cleaned.add({
          'version': '1.0',
          'updateComponents': filtered,
        });
        continue;
      }

      if (msg['updateDataModel'] is Map) {
        final src = Map<String, Object?>.from(msg['updateDataModel']! as Map);
        final filtered = <String, Object?>{
          for (final entry in src.entries)
            if (_allowedUpdateDataModelKeys.contains(entry.key))
              entry.key: entry.value,
        };
        cleaned.add({
          'version': '1.0',
          'updateDataModel': filtered,
        });
        continue;
      }

      cleaned.add(msg);
    }
    return cleaned;
  }

  static List<Map<String, Object?>> _sanitizeComponents(List<Object?> rawList) {
    final result = <Map<String, Object?>>[];
    for (final item in rawList.take(maxComponentsPerSurface)) {
      if (item is! Map) continue;
      final comp = Map<String, Object?>.from(item);
      final name = comp['component']?.toString() ?? '';
      if (_studioComponentNames.contains(name)) {
        comp['catalogId'] = StudioCatalog.id;
      }
      result.add(comp);
    }
    return result;
  }
}
