import 'alarm_sound.dart';

abstract interface class AlarmSettingsRepository {
  AlarmSound loadSound();
  Future<void> saveSound(AlarmSound sound);
}

class InMemoryAlarmSettingsRepository implements AlarmSettingsRepository {
  AlarmSound _sound;

  InMemoryAlarmSettingsRepository([
    this._sound = const AlarmSound.systemAlarm(),
  ]);

  @override
  AlarmSound loadSound() => _sound;

  @override
  Future<void> saveSound(AlarmSound sound) async => _sound = sound;
}
