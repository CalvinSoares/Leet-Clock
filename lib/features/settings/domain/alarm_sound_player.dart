import 'alarm_sound.dart';

abstract interface class AlarmSoundPlayer {
  Future<void> play(AlarmSound sound);
  Future<void> stop();
}

class NoopAlarmSoundPlayer implements AlarmSoundPlayer {
  const NoopAlarmSoundPlayer();

  @override
  Future<void> play(AlarmSound sound) async {}

  @override
  Future<void> stop() async {}
}
