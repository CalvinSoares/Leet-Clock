import 'alarm_sound.dart';

class AlarmPermissionStatus {
  const AlarmPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
    required this.batteryOptimizationDisabled,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
  final bool batteryOptimizationDisabled;
}

abstract interface class DeviceSettingsService {
  Future<AlarmPermissionStatus> permissionStatus();
  Future<bool> requestNotificationPermission();
  Future<bool> requestExactAlarmPermission();
  Future<void> openNotificationSettings();
  Future<void> openAlarmSettings();
  Future<void> openSoundSettings();
  Future<void> openBatterySettings();
  Future<AlarmSound?> pickAlarmSound(AlarmSound current);
}

class NoopDeviceSettingsService implements DeviceSettingsService {
  const NoopDeviceSettingsService();

  @override
  Future<AlarmPermissionStatus> permissionStatus() async =>
      const AlarmPermissionStatus(
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
        batteryOptimizationDisabled: true,
      );

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> openAlarmSettings() async {}

  @override
  Future<void> openSoundSettings() async {}

  @override
  Future<void> openBatterySettings() async {}

  @override
  Future<AlarmSound?> pickAlarmSound(AlarmSound current) async => null;
}
