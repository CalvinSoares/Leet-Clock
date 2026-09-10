import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/alarm.dart';

class EditAlarmSheet extends StatefulWidget {
  const EditAlarmSheet({required this.onSave, this.alarm, super.key});

  final Alarm? alarm;
  final Future<void> Function(Alarm alarm) onSave;

  @override
  State<EditAlarmSheet> createState() => _EditAlarmSheetState();
}

class _EditAlarmSheetState extends State<EditAlarmSheet> {
  late TimeOfDay _time;
  late Set<int> _days;
  late ChallengeType _challengeType;
  late bool _snooze;
  late final String _draftId;
  late final TextEditingController _labelController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    _draftId = alarm?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _time = alarm?.time ?? const TimeOfDay(hour: 8, minute: 0);
    _days = {...?alarm?.weekdays};
    _challengeType = alarm?.challengeType ?? ChallengeType.flashcards;
    _snooze = alarm?.snoozeEnabled ?? true;
    _labelController = TextEditingController(text: alarm?.label ?? 'Alarme');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.alarm == null ? 'Novo alarme' : 'Editar alarme',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TimeSelector(
                time: _time,
                onChanged: (value) => setState(() => _time = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Repetir:',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: AppSpacing.sm),
              _WeekdaySelector(
                selected: _days,
                onChanged: (day) => setState(() => _toggleDay(day)),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Etiqueta',
                  hintText: 'Alarme',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ChallengeType>(
                initialValue: _challengeType,
                decoration: const InputDecoration(
                  labelText: 'Desafio para desligar',
                ),
                items: const [
                  DropdownMenuItem(
                    value: ChallengeType.flashcards,
                    child: Text('Flashcards'),
                  ),
                  DropdownMenuItem(
                    value: ChallengeType.leetcode,
                    child: Text('LeetCode'),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _challengeType = value ?? ChallengeType.flashcards,
                ),
              ),
              Row(
                children: [
                  const Expanded(child: Text('Permitir adiar')),
                  Switch.adaptive(
                    value: _snooze,
                    onChanged: (value) => setState(() => _snooze = value),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancelar',
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: _isSaving ? 'Salvando...' : 'Salvar',
                    onPressed: _isSaving ? null : _save,
                    primary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDay(int day) {
    if (_days.contains(day)) {
      _days.remove(day);
    } else {
      _days.add(day);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final current = widget.alarm;
    final alarm = Alarm(
      id: _draftId,
      time: _time,
      label: _labelController.text.trim().isEmpty
          ? 'Alarme'
          : _labelController.text.trim(),
      weekdays: _days,
      challengeType: _challengeType,
      enabled: current?.enabled ?? true,
      snoozeEnabled: _snooze,
    );
    try {
      await widget.onSave(alarm);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o alarme.')),
      );
    }
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({required this.time, required this.onChanged});

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selected != null) onChanged(selected);
      },
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.input,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Center(
          child: Text(
            '${time.hour.toString().padLeft(2, '0')} : ${time.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < labels.length; index++)
          Semantics(
            label: 'Repetir toda ${_fullDay(index + 1)}',
            button: true,
            selected: selected.contains(index + 1),
            child: InkWell(
              onTap: () => onChanged(index + 1),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected.contains(index + 1)
                      ? AppColors.focused
                      : AppColors.input,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: selected.contains(index + 1)
                        ? AppColors.accent
                        : AppColors.border,
                  ),
                ),
                child: Text(labels[index]),
              ),
            ),
          ),
      ],
    );
  }
}

String _fullDay(int day) => const [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
][day - 1];
