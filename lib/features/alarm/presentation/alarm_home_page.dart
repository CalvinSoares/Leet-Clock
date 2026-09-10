import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../challenge/presentation/challenge_page.dart';
import '../../challenge/domain/challenge_validator.dart';
import '../../settings/domain/alarm_settings_repository.dart';
import '../../settings/domain/alarm_sound_player.dart';
import '../../settings/domain/device_settings_service.dart';
import '../../settings/presentation/settings_page.dart';
import '../domain/alarm.dart';
import '../domain/alarm_repository.dart';
import '../domain/alarm_scheduler.dart';
import 'alarm_view_model.dart';
import 'edit_alarm_sheet.dart';

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({
    this.repository,
    this.scheduler,
    this.challengeValidator,
    this.settingsRepository,
    this.soundPlayer,
    this.deviceSettings,
    super.key,
  });

  final AlarmRepository? repository;
  final AlarmScheduler? scheduler;
  final ChallengeValidator? challengeValidator;
  final AlarmSettingsRepository? settingsRepository;
  final AlarmSoundPlayer? soundPlayer;
  final DeviceSettingsService? deviceSettings;

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  late final AlarmViewModel _viewModel;
  DateTime? _now;
  Timer? _clockTimer;
  late final AlarmSettingsRepository _settingsRepository;
  late final AlarmSoundPlayer _soundPlayer;
  late final DeviceSettingsService _deviceSettings;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _settingsRepository =
        widget.settingsRepository ?? InMemoryAlarmSettingsRepository();
    _soundPlayer = widget.soundPlayer ?? const NoopAlarmSoundPlayer();
    _deviceSettings =
        widget.deviceSettings ?? const NoopDeviceSettingsService();
    _viewModel = AlarmViewModel(
      repository: widget.repository,
      scheduler: widget.scheduler,
    )..addListener(_onChanged);
    _viewModel.initialize();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _tick() {
    if (!mounted) return;

    final now = DateTime.now();
    setState(() => _now = now);

    final dueAlarm = _viewModel.checkDue(now);
    if (dueAlarm != null) _openTriggeredAlarm(dueAlarm);
  }

  Future<void> _openEditor([Alarm? alarm]) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: EditAlarmSheet(alarm: alarm, onSave: _viewModel.save),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          repository: _settingsRepository,
          soundPlayer: _soundPlayer,
          deviceSettings: _deviceSettings,
        ),
      ),
    );
    _viewModel.rescheduleAll();
  }

  void _testAlarm(Alarm alarm) {
    unawaited(_openAlarmChallenge(alarm, triggered: false));
  }

  void _openTriggeredAlarm(Alarm alarm) {
    unawaited(_openAlarmChallenge(alarm, triggered: true));
  }

  Future<void> _openAlarmChallenge(
    Alarm alarm, {
    required bool triggered,
  }) async {
    unawaited(_startRinging(alarm));
    final solved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChallengePage(
          alarm: alarm,
          validator: widget.challengeValidator,
          onSolved: () {
            unawaited(_viewModel.stopRinging(alarm));
            if (triggered && alarm.weekdays.isEmpty) {
              unawaited(_viewModel.toggle(alarm, false));
            }
          },
        ),
      ),
    );
    if (!mounted || solved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Desafio concluído. Alarme desligado!')),
    );
  }

  Future<void> _startRinging(Alarm alarm) async {
    try {
      final permissionGranted = await _viewModel.requestPermissions();
      if (!permissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'O teste tocará normalmente. Ative as notificações para receber alarmes com o app fechado.',
              ),
            ),
          );
        }
      }
      await _viewModel.ringNow(alarm);
    } catch (error) {
      debugPrint('Falha ao tocar o alarme: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível iniciar o som. Verifique o volume de alarme do aparelho.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _viewModel.nextAlarm;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leet Clock'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: () => _showInfo(context),
            tooltip: 'Como funciona',
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            const Text(
              'Bom dia, Calvin',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatNow(_now ?? DateTime.now()),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (next != null)
              _NextAlarmCard(alarm: next, onTest: () => _testAlarm(next)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seus alarmes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                AppButton(
                  label: 'Adicionar',
                  icon: Icons.add,
                  onPressed: _openEditor,
                  primary: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ..._viewModel.alarms.map(
              (alarm) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _AlarmTile(
                  alarm: alarm,
                  onChanged: (value) => _viewModel.toggle(alarm, value),
                  onEdit: () => _openEditor(alarm),
                  onTest: () => _testAlarm(alarm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNow(DateTime now) {
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leet Clock sem soneca'),
        content: const Text(
          'Quando o alarme tocar, resolva um desafio de código ou acerte o flashcard para desligá-lo.',
        ),
        actions: [
          AppButton(
            label: 'Entendi',
            onPressed: () => Navigator.pop(context),
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _NextAlarmCard extends StatelessWidget {
  const _NextAlarmCard({required this.alarm, required this.onTest});

  final Alarm alarm;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.accent),
              SizedBox(width: AppSpacing.xs),
              Text(
                'PRÓXIMO ALARME',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _timeLabel(alarm.time),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            alarm.label,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Testar desafio',
            icon: Icons.play_arrow_rounded,
            onPressed: onTest,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.alarm,
    required this.onChanged,
    required this.onEdit,
    required this.onTest,
  });

  final Alarm alarm;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeLabel(alarm.time),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alarm.label,
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  Text(
                    _daysLabel(alarm.weekdays),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onTest,
            tooltip: 'Testar desafio',
            icon: const Icon(Icons.bolt_outlined),
          ),
          Switch(value: alarm.enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

String _timeLabel(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _daysLabel(Set<int> days) {
  const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  if (days.length == 7) return 'Todos os dias';
  if (days.isEmpty) return 'Uma vez';
  final sorted = days.toList()..sort();
  return sorted.map((day) => labels[day - 1]).join(' · ');
}
