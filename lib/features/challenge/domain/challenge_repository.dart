import '../../alarm/domain/alarm.dart';
import 'challenge.dart';

abstract interface class ChallengeRepository {
  Challenge nextFor(ChallengeType type);
}

class LocalChallengeRepository implements ChallengeRepository {
  @override
  Challenge nextFor(ChallengeType type) {
    if (type == ChallengeType.leetcode) {
      return const Challenge(
        id: 'two-sum-001',
        type: ChallengeType.leetcode,
        title: 'Two Sum · Fácil',
        prompt: 'Implemente two_sum(nums, target) e retorne os índices dos dois valores que somam o target.',
        answer: '[0, 1]',
        hint: 'Procure o par 2 + 7.',
        starterCode:
            'def two_sum(nums, target):\n    # escreva sua solução\n    pass',
      );
    }
    return const Challenge(
      id: 'dart-collections-001',
      type: ChallengeType.flashcards,
      title: 'Flashcard de revisão',
      prompt:
          'Qual método transforma uma lista em uma sequência de itens em Dart?',
      answer: 'map',
      options: ['map', 'where', 'fold', 'reduce'],
    );
  }
}
