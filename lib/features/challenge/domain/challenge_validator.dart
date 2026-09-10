import 'dart:convert';

import 'package:http/http.dart' as http;

import 'challenge.dart';

class ValidationResult {
  const ValidationResult({required this.accepted, this.message});

  final bool accepted;
  final String? message;
}

abstract interface class ChallengeValidator {
  Future<ValidationResult> validate({
    required Challenge challenge,
    required String answer,
  });
}

class LocalChallengeValidator implements ChallengeValidator {
  const LocalChallengeValidator();

  @override
  Future<ValidationResult> validate({
    required Challenge challenge,
    required String answer,
  }) async {
    final normalized = _normalize(answer);
    final expected = _normalize(challenge.answer);
    return ValidationResult(
      accepted: normalized == expected,
      message: normalized == expected
          ? 'Resposta aceita.'
          : 'Resposta incorreta.',
    );
  }
}

class RemoteChallengeValidator implements ChallengeValidator {
  RemoteChallengeValidator({
    required this.baseUri,
    this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Uri baseUri;
  final String? token;
  final http.Client _client;

  @override
  Future<ValidationResult> validate({
    required Challenge challenge,
    required String answer,
  }) async {
    final response = await _client.post(
      baseUri.resolve('/v1/challenge-runs'),
      headers: {
        'content-type': 'application/json',
        if (token != null && token!.isNotEmpty)
          'authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'challengeId': challenge.id,
        'language': 'python',
        'sourceCode': answer,
      }),
    );

    if (response.statusCode != 200) {
      throw ChallengeValidationException(
        'Servidor de desafios indisponível (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ValidationResult(
      accepted: body['status'] == 'accepted',
      message: body['message'] as String?,
    );
  }
}

class ChallengeValidationException implements Exception {
  const ChallengeValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _normalize(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
