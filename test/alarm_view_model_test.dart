import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meu_primeiro_app/features/alarm/domain/alarm.dart';
import 'package:meu_primeiro_app/features/alarm/domain/alarm_repository.dart';
import 'package:meu_primeiro_app/features/alarm/presentation/alarm_view_model.dart';

void main() {
  test('dispara um alarme uma única vez no minuto agendado', () {
    final alarm = Alarm(
      id: 'test',
      time: const TimeOfDay(hour: 7, minute: 30),
      label: 'Teste',
      weekdays: const {1},
      challengeType: ChallengeType.flashcards,
    );
    final viewModel = AlarmViewModel(repository: _FakeAlarmRepository([alarm]));
    final scheduledTime = DateTime(2026, 1, 5, 7, 30, 5);

    expect(viewModel.checkDue(scheduledTime)?.id, 'test');
    expect(
      viewModel.checkDue(scheduledTime.add(const Duration(seconds: 1))),
      isNull,
    );
  });
}

class _FakeAlarmRepository implements AlarmRepository {
  _FakeAlarmRepository(this._alarms);

  final List<Alarm> _alarms;

  @override
  List<Alarm> load() => List.unmodifiable(_alarms);

  @override
  Future<void> save(Alarm alarm) async {}

  @override
  Future<void> delete(String id) async {}
}
