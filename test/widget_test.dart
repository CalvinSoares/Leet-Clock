import 'package:flutter_test/flutter_test.dart';

import 'package:meu_primeiro_app/features/alarm/domain/alarm.dart';
import 'package:meu_primeiro_app/features/alarm/domain/alarm_repository.dart';
import 'package:meu_primeiro_app/features/settings/domain/alarm_settings_repository.dart';
import 'package:meu_primeiro_app/features/settings/domain/alarm_sound.dart';
import 'package:meu_primeiro_app/main.dart';

void main() {
  testWidgets('exibe o painel de alarmes', (WidgetTester tester) async {
    await tester.pumpWidget(const AlarmApp());

    expect(find.text('Leet Clock'), findsOneWidget);
    expect(find.text('Seus alarmes'), findsOneWidget);
    expect(find.text('Começar o dia'), findsWidgets);
  });

  testWidgets('abre o editor de novo alarme', (WidgetTester tester) async {
    await tester.pumpWidget(const AlarmApp());
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Novo alarme'), findsOneWidget);
    expect(find.text('Desafio para desligar'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets('configura e mantém o som escolhido', (
    WidgetTester tester,
  ) async {
    final settings = InMemoryAlarmSettingsRepository();
    await tester.pumpWidget(AlarmApp(settingsRepository: settings));

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Som do alarme'), findsOneWidget);
    expect(find.text('Permissões'), findsOneWidget);

    await tester.tap(find.text('Bip forte'));
    await tester.pumpAndSettle();
    expect(settings.loadSound().kind, AlarmSoundKind.strongBeep);
  });

  testWidgets('salvar várias vezes cria somente um alarme', (
    WidgetTester tester,
  ) async {
    final repository = _CountingAlarmRepository();
    await tester.pumpWidget(AlarmApp(alarmRepository: repository));
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.tap(find.text('Salvar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repository.saveCount, 1);
    expect(repository.alarms, hasLength(1));
    expect(find.text('Novo alarme'), findsNothing);
  });

  testWidgets('resposta correta conclui e volta para o início', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlarmApp());
    await tester.tap(find.text('Testar desafio'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('map'));
    await tester.tap(find.text('Verificar resposta'));
    await tester.pumpAndSettle();

    expect(find.text('Leet Clock'), findsOneWidget);
    expect(find.text('Desafio concluído. Alarme desligado!'), findsOneWidget);
  });
}

class _CountingAlarmRepository implements AlarmRepository {
  final List<Alarm> alarms = [];
  int saveCount = 0;

  @override
  List<Alarm> load() => List.unmodifiable(alarms);

  @override
  Future<void> save(Alarm alarm) async {
    saveCount++;
    final index = alarms.indexWhere((item) => item.id == alarm.id);
    if (index == -1) {
      alarms.add(alarm);
    } else {
      alarms[index] = alarm;
    }
  }

  @override
  Future<void> delete(String id) async {
    alarms.removeWhere((alarm) => alarm.id == id);
  }
}
