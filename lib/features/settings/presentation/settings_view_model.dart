import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/alarm_settings_repository.dart';
import '../domain/alarm_sound.dart';
import '../domain/alarm_sound_player.dart';
import '../domain/device_settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repository, this._soundPlayer, this._deviceSettings)
    : _selectedSound = _repository.loadSound();

  final AlarmSettingsRepository _repository;
  final AlarmSoundPlayer _soundPlayer;
  final DeviceSettingsService _deviceSettings;

  AlarmSound _selectedSound;
  AlarmPermissionStatus _permissionStatus = const AlarmPermissionStatus(
    notificationsEnabled: false,
    exactAlarmsEnabled: false,
    batteryOptimizationDisabled: false,
  );
  bool _loadingPermissions = true;
  bool _previewing = false;
  bool _changed = false;

  AlarmSound get selectedSound => _selectedSound;
  AlarmPermissionStatus get permissionStatus => _permissionStatus;
  bool get loadingPermissions => _loadingPermissions;
  bool get previewing => _previewing;
  bool get changed => _changed;

  Future<void> initialize() => refreshPermissions();

  Future<void> selectSound(AlarmSound sound) async {
    await stopPreview();
    if (_selectedSound == sound) return;
    await _repository.saveSound(sound);
    _selectedSound = sound;
    _changed = true;
    notifyListeners();
  }

  Future<void> chooseOnDevice() async {
    await stopPreview();
    final selected = await _deviceSettings.pickAlarmSound(_selectedSound);
    if (selected != null) await selectSound(selected);
  }

  Future<void> togglePreview() async {
    if (_previewing) {
      await stopPreview();
      return;
    }
    await _soundPlayer.play(_selectedSound);
    _previewing = true;
    notifyListeners();
  }

  Future<void> stopPreview() async {
    if (!_previewing) return;
    await _soundPlayer.stop();
    _previewing = false;
    notifyListeners();
  }

  Future<void> refreshPermissions() async {
    _loadingPermissions = true;
    notifyListeners();
    try {
      _permissionStatus = await _deviceSettings.permissionStatus();
    } finally {
      _loadingPermissions = false;
      notifyListeners();
    }
  }

  Future<void> configureNotifications() async {
    if (_permissionStatus.notificationsEnabled) {
      await _deviceSettings.openNotificationSettings();
    } else {
      final granted = await _deviceSettings.requestNotificationPermission();
      await refreshPermissions();
      if (!granted) await _deviceSettings.openNotificationSettings();
    }
  }

  Future<void> configureExactAlarms() async {
    if (_permissionStatus.exactAlarmsEnabled) {
      await _deviceSettings.openAlarmSettings();
    } else {
      await _deviceSettings.requestExactAlarmPermission();
      await refreshPermissions();
    }
  }

  Future<void> openSoundSettings() => _deviceSettings.openSoundSettings();

  Future<void> openBatterySettings() => _deviceSettings.openBatterySettings();

  @override
  void dispose() {
    unawaited(_soundPlayer.stop());
    super.dispose();
  }
}
