import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../alarm/domain/alarm.dart';
import '../domain/challenge.dart';
import '../domain/challenge_repository.dart';
import '../domain/challenge_validator.dart';

class ChallengePage extends StatefulWidget {
  const ChallengePage({
    required this.alarm,
    this.onSolved,
    this.validator,
    super.key,
  });

  final Alarm alarm;
  final VoidCallback? onSolved;
  final ChallengeValidator? validator;

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  late final Challenge _challenge;
  late final TextEditingController _answerController;
  String? _selectedOption;
  bool? _isCorrect;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _challenge = LocalChallengeRepository().nextFor(widget.alarm.challengeType);
    _answerController = TextEditingController(text: _challenge.starterCode);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFlashcard = _challenge.type == ChallengeType.flashcards;
    return Scaffold(
      appBar: AppBar(title: const Text('Desafio para acordar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _ChallengeHeader(challenge: _challenge),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _challenge.prompt,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (isFlashcard)
                    _FlashcardOptions(
                      challenge: _challenge,
                      selected: _selectedOption,
                      onSelected: (value) =>
                          setState(() => _selectedOption = value),
                    )
                  else
                    _CodeAnswerField(
                      controller: _answerController,
                      remote: widget.validator is RemoteChallengeValidator,
                    ),
                  if (_isCorrect == false && _challenge.hint != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Dica: ${_challenge.hint}',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isCorrect == true)
              const AppCard(
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Correto. Alarme desligado!',
                        style: TextStyle(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              )
            else
              AppButton(
                label: 'Verificar resposta',
                icon: Icons.check,
                onPressed: _isChecking ? null : _checkAnswer,
                primary: true,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAnswer() async {
    final answer = _selectedOption ?? _answerController.text;
    setState(() => _isChecking = true);
    try {
      final result = await (widget.validator ?? const LocalChallengeValidator())
          .validate(challenge: _challenge, answer: answer);
      if (!mounted) return;
      setState(() {
        _isCorrect = result.accepted;
        _isChecking = false;
      });
      if (result.accepted) {
        widget.onSolved?.call();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      if (!result.accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Ainda não. Tente novamente.'),
          ),
        );
      }
    } on ChallengeValidationException catch (error) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível validar agora.')),
      );
    }
  }
}

class _ChallengeHeader extends StatelessWidget {
  const _ChallengeHeader({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final isCode = challenge.type == ChallengeType.leetcode;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.focused,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(
            isCode ? Icons.code : Icons.style_outlined,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCode ? 'LeetCode' : 'Flashcards',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Text(
              challenge.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ],
    );
  }
}

class _FlashcardOptions extends StatelessWidget {
  const _FlashcardOptions({
    required this.challenge,
    required this.selected,
    required this.onSelected,
  });

  final Challenge challenge;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in challenge.options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: InkWell(
              onTap: () => onSelected(option),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: selected == option
                      ? AppColors.focused
                      : AppColors.input,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: selected == option
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected == option
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected == option
                          ? AppColors.accent
                          : AppColors.mutedText,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(option),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CodeAnswerField extends StatelessWidget {
  const _CodeAnswerField({required this.controller, required this.remote});

  final TextEditingController controller;
  final bool remote;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      autocorrect: false,
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        hintText: 'Digite a resposta, ex.: [0, 1]',
        labelText: remote ? 'Código Python' : 'Resposta',
      ),
    );
  }
}
