enum AlarmSoundKind { systemAlarm, ringtone, notification, strongBeep, custom }

class AlarmSound {
  const AlarmSound({required this.kind, this.uri, this.customLabel});

  const AlarmSound.systemAlarm()
    : kind = AlarmSoundKind.systemAlarm,
      uri = null,
      customLabel = null;

  final AlarmSoundKind kind;
  final String? uri;
  final String? customLabel;

  static const presets = <AlarmSound>[
    AlarmSound(kind: AlarmSoundKind.systemAlarm),
    AlarmSound(kind: AlarmSoundKind.ringtone),
    AlarmSound(kind: AlarmSoundKind.notification),
    AlarmSound(kind: AlarmSoundKind.strongBeep),
  ];

  String get title => switch (kind) {
    AlarmSoundKind.systemAlarm => 'Alarme do sistema',
    AlarmSoundKind.ringtone => 'Toque do telefone',
    AlarmSoundKind.notification => 'Som de notificação',
    AlarmSoundKind.strongBeep => 'Bip forte',
    AlarmSoundKind.custom => customLabel ?? 'Som escolhido no aparelho',
  };

  String get description => switch (kind) {
    AlarmSoundKind.systemAlarm => 'Usa o toque definido para o despertador',
    AlarmSoundKind.ringtone => 'Usa o toque de chamadas do celular',
    AlarmSoundKind.notification => 'Um alerta curto e discreto',
    AlarmSoundKind.strongBeep => 'Tom contínuo no volume de alarme',
    AlarmSoundKind.custom => 'Selecionado na biblioteca de sons do Android',
  };

  String get channelKey {
    final value = kind == AlarmSoundKind.custom ? uri ?? 'custom' : kind.name;
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return '${kind.name}_$hash';
  }

  @override
  bool operator ==(Object other) =>
      other is AlarmSound &&
      other.kind == kind &&
      other.uri == uri &&
      other.customLabel == customLabel;

  @override
  int get hashCode => Object.hash(kind, uri, customLabel);
}
