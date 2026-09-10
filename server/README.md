# Challenge API

Este serviço é o backend de referência para validar submissões de LeetCode. O app Flutter chama `POST /v1/challenge-runs`; o serviço executa somente desafios allowlisted dentro de um container descartável.

## Rodar localmente

```text
docker build -t desperta-python-runner:latest server/runner
set CHALLENGE_API_TOKEN=dev-token
dart run server/bin/server.dart
```

No app:

```text
flutter run --dart-define=CHALLENGE_API_URL=http://10.0.2.2:8080
```

Em um dispositivo físico, substitua `10.0.2.2` pelo IP da máquina que está executando o serviço. O cliente de produção deve enviar o token em um mecanismo de sessão seguro; não embuta segredo no APK.

## Contrato

`POST /v1/challenge-runs`

```json
{
  "challengeId": "two-sum-001",
  "language": "python",
  "sourceCode": "def two_sum(nums, target): ..."
}
```

Resposta aceita:

```json
{
  "status": "accepted",
  "message": "Todos os casos passaram."
}
```

O runner atual é propositalmente pequeno: suporta apenas `two_sum` e dois casos. Para produção, adicionar fila, autenticação de usuário, rate limit, observabilidade, imagens imutáveis por linguagem, microVM/gVisor/Firecracker e revisão de vulnerabilidades da imagem. `exec` e builtins restritos não são a fronteira de segurança; o isolamento do container e do runtime é obrigatório.
