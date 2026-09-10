import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/alarm_sound.dart';
import '../domain/device_settings_service.dart';

class LocalDeviceSettingsService implements DeviceSettingsService {
  LocalDeviceSettingsService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channel = MethodChannel('leet_clock/device');
  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<AlarmPermissionStatus> permissionStatus() async {
    final notifications = await _android?.areNotificationsEnabled() ?? true;
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final batteryOptimizationDisabled =
        await _channel.invokeMethod<bool>('isBatteryOptimizationDisabled') ??
        true;
    return AlarmPermissionStatus(
      notificationsEnabled: notifications,
      exactAlarmsEnabled: exact,
      batteryOptimizationDisabled: batteryOptimizationDisabled,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  @override
  Future<bool> requestExactAlarmPermission() async =>
      await _android?.requestExactAlarmsPermission() ?? true;

  @override
  Future<void> openNotificationSettings() =>
      _channel.invokeMethod<void>('openNotificationSettings');

  @override
  Future<void> openAlarmSettings() =>
      _channel.invokeMethod<void>('openAlarmSettings');

  @override
  Future<void> openSoundSettings() =>
      _channel.invokeMethod<void>('openSoundSettings');

  @override
  Future<void> openBatterySettings() =>
      _channel.invokeMethod<void>('openBatterySettings');

  @override
  Future<AlarmSound?> pickAlarmSound(AlarmSound current) async {
    final result = await _channel.invokeMapMethod<String, String>(
      'pickAlarmSound',
      {'uri': current.uri},
    );
    final uri = result?['uri'];
    if (uri == null || uri.isEmpty) return null;
    return AlarmSound(
      kind: AlarmSoundKind.custom,
      uri: uri,
      customLabel: result?['label'],
    );
  }
}
