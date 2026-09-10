import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm.dart';

abstract interface class AlarmRepository {
  List<Alarm> load();
  Future<void> save(Alarm alarm);
  Future<void> delete(String id);
}

final List<Alarm> defaultAlarms = [
  Alarm(
    id: 'morning',
    time: const TimeOfDay(hour: 7, minute: 30),
    label: 'Começar o dia',
    weekdays: {1, 2, 3, 4, 5},
    challengeType: ChallengeType.flashcards,
  ),
  Alarm(
    id: 'gym',
    time: const TimeOfDay(hour: 6, minute: 0),
    label: 'Treino',
    weekdays: {2, 4, 6},
    challengeType: ChallengeType.leetcode,
    enabled: false,
  ),
];

class InMemoryAlarmRepository implements AlarmRepository {
  final List<Alarm> _alarms = [...defaultAlarms];

  @override
  List<Alarm> load() => List.unmodifiable(_alarms);

  @override
  Future<void> save(Alarm alarm) async {
    final index = _alarms.indexWhere((item) => item.id == alarm.id);
    if (index == -1) {
      _alarms.add(alarm);
    } else {
      _alarms[index] = alarm;
    }
  }

  @override
  Future<void> delete(String id) async =>
      _alarms.removeWhere((item) => item.id == id);
}

class SharedPreferencesAlarmRepository implements AlarmRepository {
  SharedPreferencesAlarmRepository(this._preferences);

  static const _storageKey = 'desperta.alarms.v1';
  final SharedPreferences _preferences;

  @override
  List<Alarm> load() {
    final encoded = _preferences.getString(_storageKey);
    if (encoded == null) return List.unmodifiable(defaultAlarms);

    try {
      final values = jsonDecode(encoded) as List<dynamic>;
      final seen = <String>{};
      final alarms = values
          .map(_fromJson)
          .where((alarm) => seen.add(_identityOf(alarm)))
          .toList();
      return List.unmodifiable(alarms);
    } on FormatException {
      return List.unmodifiable(defaultAlarms);
    } on TypeError {
      return List.unmodifiable(defaultAlarms);
    }
  }

  @override
  Future<void> save(Alarm alarm) async {
    final alarms = [...load()];
    final index = alarms.indexWhere((item) => item.id == alarm.id);
    if (index == -1) {
      alarms.add(alarm);
    } else {
      alarms[index] = alarm;
    }
    await _write(alarms);
  }

  @override
  Future<void> delete(String id) async {
    await _write(load().where((alarm) => alarm.id != id).toList());
  }

  Future<void> _write(List<Alarm> alarms) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(alarms.map(_toJson).toList()),
    );
  }

  Map<String, Object> _toJson(Alarm alarm) => {
    'id': alarm.id,
    'hour': alarm.time.hour,
    'minute': alarm.time.minute,
    'label': alarm.label,
    'weekdays': alarm.weekdays.toList()..sort(),
    'challengeType': alarm.challengeType.name,
    'enabled': alarm.enabled,
    'snoozeEnabled': alarm.snoozeEnabled,
  };

  String _identityOf(Alarm alarm) {
    final days = alarm.weekdays.toList()..sort();
    return '${alarm.time.hour}:${alarm.time.minute}|${alarm.label}|'
        '${days.join(',')}|${alarm.challengeType.name}';
  }

  Alarm _fromJson(dynamic value) {
    final json = value as Map<String, dynamic>;
    return Alarm(
      id: json['id'] as String,
      time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
      label: json['label'] as String,
      weekdays: (json['weekdays'] as List<dynamic>).cast<int>().toSet(),
      challengeType: ChallengeType.values.byName(
        json['challengeType'] as String,
      ),
      enabled: json['enabled'] as bool? ?? true,
      snoozeEnabled: json['snoozeEnabled'] as bool? ?? true,
    );
  }
}
