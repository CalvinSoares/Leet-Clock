# Leet Clock — especificação de arquitetura e padrões

## Objetivo

O Leet Clock é um despertador que só encerra o toque depois de uma tarefa cognitiva: resolver um desafio de programação estilo LeetCode ou acertar um flashcard. A primeira entrega usa dados locais para validar o fluxo inteiro; as bordas de plataforma e rede ficam atrás de contratos para poderem ser trocadas sem reescrever a UI.

## Padrão adotado

**Feature-first + Clean Architecture + MVVM reativo**.

- `domain`: entidades, enums, regras e contratos. Não importa Flutter, plugins ou HTTP.
- `data`: implementações dos repositórios, armazenamento local, API de desafios e adaptadores nativos.
- `presentation`: páginas, widgets de feature e `ChangeNotifier` ViewModels. A tela observa estado e dispara intenções; não contém regra de negócio.
- `core`: design system, erros, utilidades e infraestrutura compartilhada.

O `ChangeNotifier` é a implementação inicial do estado reativo para manter o protótipo sem dependências externas. Em produção, os mesmos contratos podem ser conectados a Riverpod sem alterar entidades ou casos de uso.

## Estrutura de diretórios

```text
lib/
  app.dart
  main.dart
  core/
    theme/app_theme.dart
    widgets/app_card.dart
    widgets/app_button.dart
  features/
    alarm/
      domain/alarm.dart
      domain/alarm_repository.dart
      data/                 # SharedPreferences/SQLite e scheduler nativo
      presentation/
    challenge/
      domain/challenge.dart
      data/                 # API/cache de questões
      presentation/
```

## Fluxo principal

```text
AlarmViewModel
  -> AlarmRepository (local agora; SQLite/Drift depois)
  -> AlarmScheduler (notificações nativas em produção)

ChallengePage
  -> ChallengeRepository
  -> ChallengeValidator
  -> AlarmSessionController
  -> AlarmScheduler.cancel(alarmId)
```

### Máquina de estados do alarme

`scheduled → ringing → challenge_in_progress → solved → dismissed`

Respostas erradas retornam para `challenge_in_progress`. `snooze` é permitido apenas quando habilitado no alarme e move `ringing → scheduled` com o próximo horário calculado. O desligamento é idempotente: uma segunda tentativa de `cancel` não deve reativar o alarme.

## Contratos recomendados

```dart
abstract interface class AlarmScheduler {
  Future<void> schedule(Alarm alarm);
  Future<void> cancel(String alarmId);
}

abstract interface class ChallengeValidator {
  ValidationResult validate(Challenge challenge, String answer);
}
```

Implementações futuras:

- `AndroidAlarmScheduler` / `IosAlarmScheduler`: `alarm_id`, horário, recorrência, som e deep link para a sessão.
- `LocalChallengeRepository`: cache offline e fallback seguro.
- `RemoteChallengeRepository`: catálogo autenticado de questões; nunca executar código arbitrário no dispositivo.
- `LeetCodeChallengeValidator`: validar resposta estruturada contra casos de teste no backend sandbox, em vez de comparar texto.

## Design system sem repetição

`Design.md` é a fonte visual do modal. Os valores foram normalizados em `AppColors`, `AppSpacing` e `AppRadii`. Elementos repetidos usam `AppCard` e `AppButton`; cada tela compõe esses blocos e mantém somente a semântica específica da feature. Novos componentes compartilhados devem entrar em `core/widgets` apenas quando houver pelo menos dois consumidores.

Regras visuais:

- fundo `#121212`, superfície `#1E1E1E`, inputs `#2C2C2E` e foco `#3A3A3C`;
- texto primário branco e secundário `#A1A1A6`;
- horário com números tabulares e alta hierarquia;
- ações com uma única primária por contexto;
- estados de erro/sucesso sempre acompanhados de texto, não apenas cor.

## Navegação e acessibilidade

- Home lista alarmes e abre o editor como bottom sheet modal.
- A sessão de desafio é uma rota própria e não pode ser fechada por gesto enquanto o alarme estiver realmente tocando; o protótipo permite voltar para facilitar testes.
- Dias da semana têm `Semantics` com nome completo e estado selecionado.
- Todos os ícones acionáveis têm tooltip; campos possuem label/hint.
- Alvos de toque devem ter no mínimo 44dp na implementação nativa final.

## Persistência e segurança

O app usa `SharedPreferencesAlarmRepository` para persistir a coleção pequena de alarmes. Se o histórico de revisão crescer, migrar o mesmo contrato para Drift/SQLite com migrações versionadas. Tokens de API não devem ser embutidos no APK; em produção, usar sessão curta emitida pelo backend. Código enviado para execução deve usar o serviço em `server/`, com sandbox remoto e limites de CPU, memória, tempo e rede; o app nunca deve executar código recebido diretamente.

## Testes e critérios de aceite

- unit: cálculo do próximo alarme, recorrência, validação, snooze e idempotência;
- widget: editor salva horário/label/dias, switch alterna, desafio mostra erro e acerto;
- integração: alarme agendado abre a sessão correta mesmo com app encerrado;
- acessibilidade: navegação por teclado/semantics, contraste mínimo 4.5:1 e fonte ampliada.

Critério funcional do MVP: criar/editar/ativar um alarme, selecionar LeetCode ou flashcards, abrir o desafio e só exibir “Alarme desligado” após resposta correta.
