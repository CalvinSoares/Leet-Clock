import 'package:flutter/material.dart';

enum ChallengeType { leetcode, flashcards }

class Alarm {
  const Alarm({
    required this.id,
    required this.time,
    required this.label,
    required this.weekdays,
    required this.challengeType,
    this.enabled = true,
    this.snoozeEnabled = true,
  });

  final String id;
  final TimeOfDay time;
  final String label;
  final Set<int> weekdays;
  final ChallengeType challengeType;
  final bool enabled;
  final bool snoozeEnabled;

  Alarm copyWith({
    TimeOfDay? time,
    String? label,
    Set<int>? weekdays,
    ChallengeType? challengeType,
    bool? enabled,
    bool? snoozeEnabled,
  }) {
    return Alarm(
      id: id,
      time: time ?? this.time,
      label: label ?? this.label,
      weekdays: weekdays ?? this.weekdays,
      challengeType: challengeType ?? this.challengeType,
      enabled: enabled ?? this.enabled,
      snoozeEnabled: snoozeEnabled ?? this.snoozeEnabled,
    );
  }
}
