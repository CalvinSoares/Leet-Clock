import '../../alarm/domain/alarm.dart';

class Challenge {
  const Challenge({
    this.id = 'local-demo',
    required this.type,
    required this.title,
    required this.prompt,
    required this.answer,
    this.options = const [],
    this.hint,
    this.starterCode,
  });

  final String id;
  final ChallengeType type;
  final String title;
  final String prompt;
  final String answer;
  final List<String> options;
  final String? hint;
  final String? starterCode;
}
