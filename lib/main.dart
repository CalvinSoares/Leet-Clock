import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/alarm/data/local_notification_alarm_scheduler.dart';
import 'features/alarm/domain/alarm_repository.dart';
import 'features/challenge/domain/challenge_validator.dart';
import 'features/settings/data/local_device_settings_service.dart';
import 'features/settings/data/method_channel_alarm_sound_player.dart';
import 'features/settings/data/shared_preferences_alarm_settings_repository.dart';
import 'features/settings/domain/alarm_settings_repository.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 3),
    );
  } catch (error, stackTrace) {
    debugPrint('Falha ao carregar alarmes salvos: $error\n$stackTrace');
  }

  final settingsRepository = preferences == null
      ? InMemoryAlarmSettingsRepository()
      : SharedPreferencesAlarmSettingsRepository(preferences);
  const soundPlayer = MethodChannelAlarmSoundPlayer();
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final scheduler = LocalNotificationAlarmScheduler(
    plugin: notificationsPlugin,
    settingsRepository: settingsRepository,
    soundPlayer: soundPlayer,
  );
  final deviceSettings = LocalDeviceSettingsService(
    plugin: notificationsPlugin,
  );
  try {
    await scheduler.initialize().timeout(const Duration(seconds: 3));
  } catch (error, stackTrace) {
    debugPrint('Falha ao inicializar notificações: $error\n$stackTrace');
  }
  const challengeApiUrl = String.fromEnvironment('CHALLENGE_API_URL');
  const challengeApiToken = String.fromEnvironment('CHALLENGE_API_TOKEN');
  runApp(
    AlarmApp(
      alarmRepository: preferences == null
          ? null
          : SharedPreferencesAlarmRepository(preferences),
      scheduler: scheduler,
      settingsRepository: settingsRepository,
      soundPlayer: soundPlayer,
      deviceSettings: deviceSettings,
      challengeValidator: challengeApiUrl.isEmpty
          ? const LocalChallengeValidator()
          : RemoteChallengeValidator(
              baseUri: Uri.parse(challengeApiUrl),
              token: challengeApiToken.isEmpty ? null : challengeApiToken,
            ),
    ),
  );

  // Permissões podem abrir um diálogo nativo e não devem impedir o Flutter
  // de desenhar a primeira tela no modo release.
  unawaited(_requestNotificationPermissions(scheduler));
}

Future<void> _requestNotificationPermissions(
  LocalNotificationAlarmScheduler scheduler,
) async {
  try {
    await scheduler.requestPermissions();
  } catch (error, stackTrace) {
    debugPrint('Falha ao solicitar permissões: $error\n$stackTrace');
  }
}
