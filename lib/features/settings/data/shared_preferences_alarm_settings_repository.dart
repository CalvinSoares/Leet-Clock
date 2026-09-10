import 'package:shared_preferences/shared_preferences.dart';

import '../domain/alarm_settings_repository.dart';
import '../domain/alarm_sound.dart';

class SharedPreferencesAlarmSettingsRepository
    implements AlarmSettingsRepository {
  SharedPreferencesAlarmSettingsRepository(this._preferences);

  static const _kindKey = 'alarm_sound_kind';
  static const _uriKey = 'alarm_sound_uri';
  static const _labelKey = 'alarm_sound_label';

  final SharedPreferences _preferences;

  @override
  AlarmSound loadSound() {
    final storedKind = _preferences.getString(_kindKey);
    final kind = AlarmSoundKind.values.where((item) => item.name == storedKind);
    final resolvedKind = kind.isEmpty ? AlarmSoundKind.systemAlarm : kind.first;
    final uri = _preferences.getString(_uriKey);
    if (resolvedKind == AlarmSoundKind.custom && (uri == null || uri.isEmpty)) {
      return const AlarmSound.systemAlarm();
    }
    return AlarmSound(
      kind: resolvedKind,
      uri: uri,
      customLabel: _preferences.getString(_labelKey),
    );
  }

  @override
  Future<void> saveSound(AlarmSound sound) async {
    await _preferences.setString(_kindKey, sound.kind.name);
    if (sound.uri case final uri?) {
      await _preferences.setString(_uriKey, uri);
    } else {
      await _preferences.remove(_uriKey);
    }
    if (sound.customLabel case final label?) {
      await _preferences.setString(_labelKey, label);
    } else {
      await _preferences.remove(_labelKey);
    }
  }
}
