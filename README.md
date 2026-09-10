# Leet Clock

Despertador interativo em Flutter. O alarme abre um desafio de flashcards ou LeetCode; o fluxo só é concluído depois de uma resposta aceita.

## Executar o app

```text
flutter pub get
flutter run
```

Os alarmes são persistidos localmente. Para testar o backend de execução segura:

```text
docker build -t desperta-python-runner:latest server/runner
set CHALLENGE_API_TOKEN=dev-token
dart run server/bin/server.dart
flutter run --dart-define=CHALLENGE_API_URL=http://10.0.2.2:8080 --dart-define=CHALLENGE_API_TOKEN=dev-token
```

Em dispositivo físico, troque `10.0.2.2` pelo IP da máquina que executa a API. O token acima é apenas para desenvolvimento; segredos não devem ser embutidos no APK.

## Arquitetura

Veja [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para as decisões de arquitetura, persistência, scheduler nativo, máquina de estados e limites de segurança do runner.
