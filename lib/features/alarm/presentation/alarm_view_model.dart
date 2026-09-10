import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/alarm.dart';
import '../domain/alarm_repository.dart';
import '../domain/alarm_scheduler.dart';

class AlarmViewModel extends ChangeNotifier {
  AlarmViewModel({AlarmRepository? repository, AlarmScheduler? scheduler})
    : _repository = repository ?? InMemoryAlarmRepository(),
      _scheduler = scheduler ?? const NoopAlarmScheduler() {
    _alarms = _repository.load();
  }

  final AlarmRepository _repository;
  final AlarmScheduler _scheduler;
  List<Alarm> _alarms = const [];
  final Set<String> _triggeredOccurrences = <String>{};

  List<Alarm> get alarms => _alarms;

  Future<bool> requestPermissions() => _scheduler.requestPermissions().timeout(
    const Duration(minutes: 1),
    onTimeout: () => false,
  );

  Future<void> ringNow(Alarm alarm) =>
      _scheduler.ringNow(alarm).timeout(const Duration(seconds: 10));

  Future<void> stopRinging(Alarm alarm) async {
    try {
      await _scheduler.stopRinging(alarm).timeout(const Duration(seconds: 10));
    } catch (error) {
      debugPrint('Falha ao encerrar o alarme: $error');
    }
  }

  Future<void> initialize() async {
    rescheduleAll();
  }

  void rescheduleAll() {
    for (final alarm in _alarms.where((item) => item.enabled)) {
      unawaited(_scheduleSafely(alarm));
    }
  }

  Alarm? get nextAlarm {
    final now = DateTime.now();
    final enabled = _alarms.where((alarm) => alarm.enabled).toList()
      ..sort((a, b) {
        final aNext = _nextOccurrence(a, now);
        final bNext = _nextOccurrence(b, now);
        return aNext.compareTo(bNext);
      });
    return enabled.isEmpty ? null : enabled.first;
  }

  /// Returns an alarm once when its scheduled minute is reached.
  ///
  /// This is intentionally kept in the view model for the local MVP. A
  /// native scheduler should replace it when background alarms are added.
  Alarm? checkDue(DateTime now) {
    Alarm? firstDue;
    for (final alarm in _alarms) {
      if (!alarm.enabled || !_matchesSchedule(alarm, now)) continue;

      final occurrence = '${alarm.id}:${now.year}-${now.month}-${now.day}';
      if (_triggeredOccurrences.add(occurrence)) firstDue ??= alarm;
    }
    return firstDue;
  }

  Future<void> toggle(Alarm alarm, bool enabled) async {
    final updated = alarm.copyWith(enabled: enabled);
    await _repository.save(updated);
    _refresh();
    unawaited(enabled ? _scheduleSafely(updated) : _cancelSafely(alarm.id));
  }

  Future<void> save(Alarm alarm) async {
    await _repository.save(alarm);
    _refresh();
    unawaited(alarm.enabled ? _scheduleSafely(alarm) : _cancelSafely(alarm.id));
  }

  Future<void> remove(Alarm alarm) async {
    await _repository.delete(alarm.id);
    _refresh();
    unawaited(_cancelSafely(alarm.id));
  }

  Future<void> _scheduleSafely(Alarm alarm) async {
    try {
      await _scheduler.schedule(alarm).timeout(const Duration(seconds: 30));
    } catch (error) {
      debugPrint('Falha ao agendar ${alarm.id}: $error');
    }
  }

  Future<void> _cancelSafely(String alarmId) async {
    try {
      await _scheduler.cancel(alarmId).timeout(const Duration(seconds: 10));
    } catch (error) {
      debugPrint('Falha ao cancelar $alarmId: $error');
    }
  }

  void _refresh() {
    _alarms = _repository.load();
    notifyListeners();
  }

  bool _matchesSchedule(Alarm alarm, DateTime now) {
    if (alarm.time.hour != now.hour || alarm.time.minute != now.minute) {
      return false;
    }
    return alarm.weekdays.isEmpty || alarm.weekdays.contains(now.weekday);
  }

  DateTime _nextOccurrence(Alarm alarm, DateTime from) {
    for (var offset = 0; offset <= 7; offset++) {
      final date = from.add(Duration(days: offset));
      if (alarm.weekdays.isNotEmpty && !alarm.weekdays.contains(date.weekday)) {
        continue;
      }

      final candidate = DateTime(
        date.year,
        date.month,
        date.day,
        alarm.time.hour,
        alarm.time.minute,
      );
      if (!candidate.isBefore(from)) return candidate;
    }

    return from.add(const Duration(days: 8));
  }
}
