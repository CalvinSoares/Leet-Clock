import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/alarm/domain/alarm_repository.dart';
import 'features/alarm/domain/alarm_scheduler.dart';
import 'features/challenge/domain/challenge_validator.dart';
import 'features/alarm/presentation/alarm_home_page.dart';
import 'features/settings/domain/alarm_settings_repository.dart';
import 'features/settings/domain/alarm_sound_player.dart';
import 'features/settings/domain/device_settings_service.dart';

class AlarmApp extends StatelessWidget {
  const AlarmApp({
    this.alarmRepository,
    this.scheduler,
    this.challengeValidator,
    this.settingsRepository,
    this.soundPlayer,
    this.deviceSettings,
    super.key,
  });

  final AlarmRepository? alarmRepository;
  final AlarmScheduler? scheduler;
  final ChallengeValidator? challengeValidator;
  final AlarmSettingsRepository? settingsRepository;
  final AlarmSoundPlayer? soundPlayer;
  final DeviceSettingsService? deviceSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leet Clock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: AlarmHomePage(
        repository: alarmRepository,
        scheduler: scheduler,
        challengeValidator: challengeValidator,
        settingsRepository: settingsRepository,
        soundPlayer: soundPlayer,
        deviceSettings: deviceSettings,
      ),
    );
  }
}
