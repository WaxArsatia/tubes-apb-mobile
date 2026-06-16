import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.onTokensRefreshed,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Future<void> Function(AuthTokens tokens)? onTokensRefreshed;
  AuthTokens? tokens;

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _sendWithRefresh(
      () => _client.get(_uri(path), headers: _headers()),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _sendWithRefresh(
      () => _client.post(
        _uri(path),
        headers: _headers(json: true),
        body: jsonEncode(body),
      ),
      refreshable: path != '/auth/refresh',
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _sendWithRefresh(
      () => _client.patch(
        _uri(path),
        headers: _headers(json: true),
        body: jsonEncode(body),
      ),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _sendWithRefresh(
      () => _client.delete(_uri(path), headers: _headers()),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(String filePath) async {
    final request = http.MultipartRequest('POST', _uri('/profile/photo'));
    final token = tokens?.accessToken;
    if (token != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));
    final streamed = await request.send();
    return _handle(await http.Response.fromStream(streamed));
  }

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function() send, {
    bool refreshable = true,
  }) async {
    final response = await send();
    if (!refreshable ||
        response.statusCode != 401 ||
        tokens?.refreshToken == null) {
      return response;
    }
    final refreshed = await _client.post(
      _uri('/auth/refresh'),
      headers: _headers(json: true),
      body: jsonEncode({'refreshToken': tokens!.refreshToken}),
    );
    if (refreshed.statusCode < 200 || refreshed.statusCode >= 300) {
      return response;
    }
    final envelope = _handle(refreshed);
    final data = (envelope['data'] as Map<String, dynamic>?) ?? envelope;
    final nextTokens = AuthTokens.fromJson(
      (data['tokens'] as Map<String, dynamic>?) ?? data,
    );
    tokens = nextTokens;
    await onTokensRefreshed?.call(nextTokens);
    return send();
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (json) {
      headers[HttpHeaders.contentTypeHeader] =
          'application/json; charset=UTF-8';
    }
    final token = tokens?.accessToken;
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _handle(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final error = decoded['error'] as Map<String, dynamic>?;
    throw ApiException(
      error?['message'] as String? ?? 'Terjadi kesalahan server',
      code: error?['code'] as String?,
      statusCode: response.statusCode,
    );
  }
}
