import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/constants.dart';
import '../models/models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, {Map<String, String>? query, String? token}) {
    final base = Uri.parse(AppConstants.apiBaseUrl);
    return base.replace(
      queryParameters: {
        if (path.isNotEmpty) 'path': path.replaceFirst('/', ''),
        if (token != null && token.isNotEmpty) 'token': token,
        ...?query,
      },
    );
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    final body = response.body.trim();
    if (body.isEmpty) {
      throw ApiException('Empty response from server', statusCode: response.statusCode);
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid server response', statusCode: response.statusCode);
    }
    if (response.statusCode >= 400 || decoded['ok'] == false) {
      throw ApiException(
        '${decoded['error'] ?? 'Request failed'}',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final payload = {
      'path': path.replaceFirst('/', ''),
      ...?body,
    };
    final response = await _client.post(
      _uri('', token: token),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    String? token,
  }) async {
    final response = await _client.get(
      _uri(path, query: query, token: token),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> adminLogin(String password) async {
    return post('/auth/admin', body: {'password': password});
  }

  Future<Map<String, dynamic>> parentLogin(String phone) async {
    return post('/auth/parent', body: {'phone': phone});
  }

  Future<SyncData> sync({
    required String role,
    String? token,
    String? phone,
  }) async {
    final result = await get(
      '/sync',
      token: token,
      query: {
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return SyncData.fromJson(Map<String, dynamic>.from(result['data'] as Map));
  }

  Future<Map<String, dynamic>> crud(
    String resource,
    String action, {
    required String token,
    Map<String, dynamic>? data,
    String? id,
  }) async {
    return post(
      '/$resource',
      token: token,
      body: {
        'action': action,
        if (id != null) 'id': id,
        if (data != null) 'data': data,
      },
    );
  }

  Future<String> uploadMedia({
    required String token,
    required String base64Data,
    required String fileName,
    required String mimeType,
  }) async {
    final result = await post(
      '/media/upload',
      token: token,
      body: {
        'fileName': fileName,
        'mimeType': mimeType,
        'data': base64Data,
      },
    );
    return '${result['url'] ?? result['data']?['url'] ?? ''}';
  }
}
