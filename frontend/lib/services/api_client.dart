import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:contract_english_trainer/config/env.dart';

class ApiClient {
  final String baseUrl;
  final Future<String?> Function() getToken;

  ApiClient({
    String? baseUrl,
    required this.getToken,
  }) : baseUrl = baseUrl ?? Env.apiBaseUrl;

  Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  /// GET a path that returns a JSON array (e.g. /vocabulary/due, /quizzes/history).
  Future<List<dynamic>> getList(String path) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleListResponse(response);
  }

  /// PUT a JSON body and return the decoded JSON object.
  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields,
    Map<String, List<int>> files, // filename -> bytes
  ) async {
    final url = Uri.parse('$baseUrl$path');
    final token = await getToken();
    final request = http.MultipartRequest('POST', url);
    fields.forEach((k, v) => request.fields[k] = v);
    files.forEach((filename, bytes) {
      // Filenames travel in an HTTP header (ASCII only) - replace non-ASCII
      // characters (e.g. Arabic file names) but keep the extension, which is
      // all the backend needs for type detection.
      final safe = filename.replaceAll(RegExp(r'[^\x20-\x7E]'), '_');
      request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: safe));
    });
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final streamedResponse = await request.send();
    // Decode as UTF-8 directly. Wrapping the decoded string in http.Response
    // re-encodes it as Latin-1, which crashes on Arabic titles/content.
    final bytes = await streamedResponse.stream.toBytes();
    final body = utf8.decode(bytes);
    if (streamedResponse.statusCode >= 200 &&
        streamedResponse.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw ApiException(streamedResponse.statusCode, body);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, body);
    }
  }

  List<dynamic> _handleListResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(body) as List<dynamic>;
    } else {
      throw ApiException(response.statusCode, body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
