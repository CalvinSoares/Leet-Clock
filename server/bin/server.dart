import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _maxBodyBytes = 64 * 1024;
const _runnerImage = String.fromEnvironment(
  'RUNNER_IMAGE',
  defaultValue: 'desperta-python-runner:latest',
);

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Desperta challenge API listening on :$port');

  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  try {
    if (request.method == 'GET' && request.uri.path == '/health') {
      await _json(request.response, 200, {'status': 'ok'});
      return;
    }

    if (request.method != 'POST' || request.uri.path != '/v1/challenge-runs') {
      await _json(request.response, 404, {'error': 'not_found'});
      return;
    }

    final expectedToken = Platform.environment['CHALLENGE_API_TOKEN'];
    if (expectedToken == null || expectedToken.isEmpty) {
      await _json(request.response, 500, {
        'error': 'server_misconfigured',
        'message': 'CHALLENGE_API_TOKEN must be configured.',
      });
      return;
    }
    if (request.headers.value('authorization') != 'Bearer $expectedToken') {
      await _json(request.response, 401, {'error': 'unauthorized'});
      return;
    }

    final body = await _readJson(request);
    final challengeId = body['challengeId'];
    final language = body['language'];
    final sourceCode = body['sourceCode'];
    if (challengeId != 'two-sum-001' ||
        language != 'python' ||
        sourceCode is! String ||
        sourceCode.trim().isEmpty) {
      await _json(request.response, 400, {'error': 'invalid_submission'});
      return;
    }

    final result = await _runInContainer(sourceCode);
    await _json(request.response, 200, result);
  } on _PayloadTooLargeException {
    await _json(request.response, 413, {'error': 'payload_too_large'});
  } on FormatException {
    await _json(request.response, 400, {'error': 'invalid_json'});
  } on TimeoutException {
    await _json(request.response, 200, {
      'status': 'failed',
      'message': 'Execução excedeu o tempo limite.',
    });
  } catch (error) {
    stderr.writeln(error);
    await _json(request.response, 500, {'error': 'runner_unavailable'});
  }
}

Future<Map<String, dynamic>> _runInContainer(String sourceCode) async {
  final process = await Process.start('docker', [
    'run',
    '--rm',
    '--interactive',
    '--network=none',
    '--read-only',
    '--tmpfs',
    '/tmp:rw,noexec,nosuid,size=16m',
    '--memory=128m',
    '--cpus=0.5',
    '--pids-limit=32',
    '--ulimit',
    'nofile=64:64',
    '--security-opt',
    'no-new-privileges:true',
    '--cap-drop=ALL',
    '--user',
    '65532:65532',
    _runnerImage,
  ]);

  process.stdin.write(jsonEncode({'sourceCode': sourceCode}));
  await process.stdin.close();

  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode.timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      process.kill(ProcessSignal.sigkill);
      throw TimeoutException('runner timeout');
    },
  );
  final output = await stdoutFuture;
  final errors = await stderrFuture;
  if (exitCode != 0) {
    return {
      'status': 'failed',
      'message': errors.trim().isEmpty ? 'Execução falhou.' : errors.trim(),
    };
  }

  final result = jsonDecode(output) as Map<String, dynamic>;
  return result;
}

Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
  final bytes = <int>[];
  await for (final chunk in request) {
    bytes.addAll(chunk);
    if (bytes.length > _maxBodyBytes) throw _PayloadTooLargeException();
  }
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

Future<void> _json(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> body,
) async {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

class _PayloadTooLargeException implements Exception {}
