import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../settings/domain/alarm_settings_repository.dart';
import '../../settings/domain/alarm_sound.dart';
import '../../settings/domain/alarm_sound_player.dart';
import '../domain/alarm.dart';
import '../domain/alarm_scheduler.dart';

class LocalNotificationAlarmScheduler implements AlarmScheduler {
  LocalNotificationAlarmScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    AlarmSettingsRepository? settingsRepository,
    AlarmSoundPlayer? soundPlayer,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _settingsRepository =
           settingsRepository ?? InMemoryAlarmSettingsRepository(),
       _soundPlayer = soundPlayer ?? const NoopAlarmSoundPlayer();

  static const _channelPrefix = 'leet_clock_alarm_v5';
  static const _channelName = 'Alarmes';
  static const _channelDescription =
      'Alarmes que exigem um desafio para desligar';
  static const _pluginTimeout = Duration(seconds: 8);
  static const _deviceChannel = MethodChannel('leet_clock/device');
  final FlutterLocalNotificationsPlugin _plugin;
  final AlarmSettingsRepository _settingsRepository;
  final AlarmSoundPlayer _soundPlayer;
  Future<void>? _initialization;
  final StreamController<String> _alarmOpened =
      StreamController<String>.broadcast();

  Stream<String> get alarmOpened => _alarmOpened.stream;

  @override
  Future<void> initialize() {
    final current = _initialization;
    if (current != null) return current;

    late final Future<void> attempt;
    attempt = _initialize().onError((error, stackTrace) {
      // Uma falha transitória do plugin não pode inutilizar o alarme durante
      // toda a execução do app. A próxima tentativa inicializa novamente.
      if (identical(_initialization, attempt)) _initialization = null;
      Error.throwWithStackTrace(
        error ?? StateError('Falha desconhecida ao inicializar notificações'),
        stackTrace,
      );
    });
    _initialization = attempt;
    return attempt;
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    await _setLocalTimeZone();
    const settings = InitializationSettings(
      // flutter_local_notifications procura o nome dentro de res/drawable.
      android: AndroidInitializationSettings('leet_clock_icon'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _alarmOpened.add(payload);
      },
    );
    await _ensureChannel(_settingsRepository.loadSound());
  }

  Future<void> _setLocalTimeZone() async {
    try {
      final name = await _deviceChannel
          .invokeMethod<String>('getTimeZone')
          .timeout(const Duration(seconds: 2));
      if (name != null && name.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(name));
        return;
      }
    } catch (error) {
      debugPrint('Não foi possível obter o fuso do aparelho: $error');
    }
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
  }

  @override
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final notificationGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final macosGranted = await macos?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (notificationGranted ?? true) &&
        (iosGranted ?? true) &&
        (macosGranted ?? true);
  }

  @override
  Future<void> schedule(Alarm alarm) async {
    await initialize().timeout(_pluginTimeout);
    await cancel(alarm.id);
    if (!alarm.enabled) return;
    final scheduleMode = await _androidScheduleMode();
    final sound = _settingsRepository.loadSound();
    await _ensureChannel(sound);
    final details = _notificationDetails(sound);

    if (alarm.weekdays.isEmpty) {
      await _scheduleOne(
        id: _notificationId(alarm.id, 0),
        alarm: alarm,
        date: _nextDate(alarm.time),
        details: details,
        scheduleMode: scheduleMode,
      );
      return;
    }

    for (final weekday in alarm.weekdays) {
      await _scheduleOne(
        id: _notificationId(alarm.id, weekday),
        alarm: alarm,
        date: _nextWeekdayDate(alarm.time, weekday),
        details: details,
        scheduleMode: scheduleMode,
        repeatsWeekly: true,
      );
    }
  }

  @override
  Future<void> ringNow(Alarm alarm) async {
    final sound = _settingsRepository.loadSound();
    Object? nativeError;
    var nativeStarted = false;
    try {
      await _soundPlayer.play(sound).timeout(const Duration(seconds: 3));
      nativeStarted = true;
    } catch (error) {
      nativeError = error;
      debugPrint('Falha ao iniciar o toque nativo: $error');
    }

    try {
      await initialize().timeout(_pluginTimeout);
      await _ensureChannel(sound);
      await _plugin.show(
        _ringingNotificationId(alarm.id),
        'Leet Clock agora',
        '${alarm.label} — resolva o desafio para desligar',
        _notificationDetails(sound),
        payload: alarm.id,
      );
    } catch (notificationError) {
      debugPrint(
        'Falha ao publicar a notificação do alarme: $notificationError',
      );
      if (!nativeStarted) {
        throw StateError(
          'Toque nativo: $nativeError; notificação: $notificationError',
        );
      }
    }

    if (!nativeStarted && nativeError != null) {
      // A notificação foi publicada e ainda poderá emitir som. Não falhamos o
      // teste por isso, mas o diagnóstico permanece disponível no log.
      debugPrint('O alarme está usando somente o som da notificação.');
    }
  }

  @override
  Future<void> stopRinging(Alarm alarm) async {
    try {
      await _soundPlayer.stop().timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('Falha ao parar o toque nativo: $error');
    }
    try {
      await _plugin.cancel(_ringingNotificationId(alarm.id));
    } catch (error) {
      debugPrint('Falha ao remover a notificação do alarme: $error');
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required Alarm alarm,
    required DateTime date,
    required NotificationDetails details,
    required AndroidScheduleMode scheduleMode,
    bool repeatsWeekly = false,
  }) {
    return _plugin.zonedSchedule(
      id,
      'Hora do Leet Clock',
      '${alarm.label} — resolva o desafio para desligar',
      tz.TZDateTime.from(date, tz.local),
      details,
      androidScheduleMode: scheduleMode,
      payload: alarm.id,
      matchDateTimeComponents: repeatsWeekly
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
    );
  }

  @override
  Future<void> cancel(String alarmId) async {
    await _plugin.cancel(_notificationId(alarmId, 0));
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_notificationId(alarmId, weekday));
    }
  }

  DateTime _nextDate(TimeOfDay time) {
    final now = DateTime.now();
    var result = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!result.isAfter(now)) result = result.add(const Duration(days: 1));
    return result;
  }

  DateTime _nextWeekdayDate(TimeOfDay time, int weekday) {
    var result = _nextDate(time);
    while (result.weekday != weekday) {
      result = result.add(const Duration(days: 1));
    }
    return result;
  }

  int _notificationId(String alarmId, int weekday) {
    var hash = 17;
    for (final codeUnit in alarmId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return (hash % 100000) * 10 + weekday;
  }

  int _ringingNotificationId(String alarmId) => _notificationId(alarmId, 8);

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    final canScheduleExact = await android.canScheduleExactNotifications();
    if (canScheduleExact ?? true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final granted = await android.requestExactAlarmsPermission();
    return granted == true
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  String _channelId(AlarmSound sound) =>
      '${_channelPrefix}_${sound.channelKey}';

  AndroidNotificationSound? _androidSound(AlarmSound sound) =>
      switch (sound.kind) {
        AlarmSoundKind.systemAlarm ||
        AlarmSoundKind.strongBeep => const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
        AlarmSoundKind.ringtone => const UriAndroidNotificationSound(
          'content://settings/system/ringtone',
        ),
        AlarmSoundKind.notification => null,
        AlarmSoundKind.custom =>
          sound.uri == null ? null : UriAndroidNotificationSound(sound.uri!),
      };

  Future<void> _ensureChannel(AlarmSound sound) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId(sound),
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: _androidSound(sound),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  NotificationDetails _notificationDetails(AlarmSound sound) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId(sound),
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          playSound: true,
          sound: _androidSound(sound),
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(presentSound: true),
        macOS: const DarwinNotificationDetails(presentSound: true),
      );
}
