import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/alarm_settings_repository.dart';
import '../domain/alarm_sound.dart';
import '../domain/alarm_sound_player.dart';
import '../domain/device_settings_service.dart';
import 'settings_view_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.repository,
    required this.soundPlayer,
    required this.deviceSettings,
    super.key,
  });

  final AlarmSettingsRepository repository;
  final AlarmSoundPlayer soundPlayer;
  final DeviceSettingsService deviceSettings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = SettingsViewModel(
      widget.repository,
      widget.soundPlayer,
      widget.deviceSettings,
    )..addListener(_onChanged);
    unawaited(_run(_viewModel.initialize));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_run(_viewModel.refreshPermissions));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Falha nas configurações: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível concluir. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Configurações'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            const _SectionHeader(
              title: 'Som do alarme',
              subtitle: 'Usado nos testes e em todos os alarmes ativos.',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < AlarmSound.presets.length;
                    index++
                  ) ...[
                    _SoundTile(
                      sound: AlarmSound.presets[index],
                      selected:
                          _viewModel.selectedSound.kind ==
                          AlarmSound.presets[index].kind,
                      onTap: () => _run(
                        () => _viewModel.selectSound(AlarmSound.presets[index]),
                      ),
                    ),
                    if (index < AlarmSound.presets.length - 1)
                      const Divider(height: 1),
                  ],
                  const Divider(height: 1),
                  _SoundTile(
                    sound:
                        _viewModel.selectedSound.kind == AlarmSoundKind.custom
                        ? _viewModel.selectedSound
                        : const AlarmSound(
                            kind: AlarmSoundKind.custom,
                            customLabel: 'Escolher no aparelho',
                          ),
                    selected:
                        _viewModel.selectedSound.kind == AlarmSoundKind.custom,
                    onTap: () => _run(_viewModel.chooseOnDevice),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _viewModel.previewing ? 'Parar teste' : 'Testar som',
                    icon: _viewModel.previewing
                        ? Icons.stop_rounded
                        : Icons.volume_up_outlined,
                    primary: true,
                    onPressed: () => _run(_viewModel.togglePreview),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: 'Volume',
                  icon: Icons.tune,
                  onPressed: () => _run(_viewModel.openSoundSettings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(
              title: 'Permissões',
              subtitle:
                  'Necessárias para tocar no horário mesmo com o app fechado.',
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PermissionTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notificações',
                    description: 'Exibe e toca o alarme em segundo plano.',
                    enabled: _viewModel.permissionStatus.notificationsEnabled,
                    loading: _viewModel.loadingPermissions,
                    onTap: () => _run(_viewModel.configureNotifications),
                  ),
                  const Divider(height: 1),
                  _PermissionTile(
                    icon: Icons.alarm_on_outlined,
                    title: 'Alarmes exatos',
                    description: 'Permite disparar no minuto programado.',
                    enabled: _viewModel.permissionStatus.exactAlarmsEnabled,
                    loading: _viewModel.loadingPermissions,
                    onTap: () => _run(_viewModel.configureExactAlarms),
                  ),
                  const Divider(height: 1),
                  _PermissionTile(
                    icon: Icons.battery_saver_outlined,
                    title: 'Economia de bateria',
                    description: 'Evita que o sistema atrase o alarme.',
                    enabled:
                        _viewModel.permissionStatus.batteryOptimizationDisabled,
                    loading: _viewModel.loadingPermissions,
                    onTap: () => _run(_viewModel.openBatterySettings),
                    enabledLabel: 'Liberado',
                    disabledLabel: 'Configurar',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: const TextStyle(color: AppColors.secondaryText)),
      ],
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.sound,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final AlarmSound sound;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppColors.accent : AppColors.mutedText,
        ),
        title: Text(sound.title),
        subtitle: Text(
          sound.description,
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.loading,
    required this.onTap,
    this.enabledLabel = 'Permitido',
    this.disabledLabel = 'Ativar',
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  final String enabledLabel;
  final String disabledLabel;

  @override
  Widget build(BuildContext context) {
    final statusColor = enabled ? AppColors.success : AppColors.danger;
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title),
      subtitle: Text(
        description,
        style: const TextStyle(color: AppColors.secondaryText),
      ),
      trailing: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  enabled ? enabledLabel : disabledLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
      onTap: loading ? null : onTap,
    );
  }
}
