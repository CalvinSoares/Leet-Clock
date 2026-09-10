import 'alarm.dart';

abstract interface class AlarmScheduler {
  Future<void> initialize();
  Future<void> schedule(Alarm alarm);
  Future<void> cancel(String alarmId);
  Future<void> ringNow(Alarm alarm);
  Future<void> stopRinging(Alarm alarm);
  Future<bool> requestPermissions();
}

class NoopAlarmScheduler implements AlarmScheduler {
  const NoopAlarmScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedule(Alarm alarm) async {}

  @override
  Future<void> cancel(String alarmId) async {}

  @override
  Future<void> ringNow(Alarm alarm) async {}

  @override
  Future<void> stopRinging(Alarm alarm) async {}

  @override
  Future<bool> requestPermissions() async => true;
}
