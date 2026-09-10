import 'package:flutter/services.dart';

import '../domain/alarm_sound.dart';
import '../domain/alarm_sound_player.dart';

class MethodChannelAlarmSoundPlayer implements AlarmSoundPlayer {
  const MethodChannelAlarmSoundPlayer();

  static const _channel = MethodChannel('leet_clock/device');

  @override
  Future<void> play(AlarmSound sound) async {
    final started = await _channel.invokeMethod<bool>('startAlarm', {
      'soundType': sound.kind.name,
      'uri': sound.uri,
    });
    if (started != true) {
      throw StateError('O Android não iniciou o som selecionado');
    }
  }

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stopAlarm');
}
