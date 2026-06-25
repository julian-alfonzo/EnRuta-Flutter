import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final List<Map<String, String>>? details;

  ApiException({
    required this.statusCode,
    this.code = 'UNKNOWN',
    required this.message,
    this.details,
  });

  factory ApiException.fromResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final error = body['error'] as Map<String, dynamic>?;
      final details = (error?['details'] as List<dynamic>?)
          ?.map((d) => Map<String, String>.from(d as Map))
          .toList();
      return ApiException(
        statusCode: response.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN',
        message: error?['message'] as String? ?? response.reasonPhrase ?? 'Error desconocido',
        details: details,
      );
    } catch (_) {
      return ApiException(
        statusCode: response.statusCode,
        message: response.reasonPhrase ?? 'Error desconocido',
      );
    }
  }

  factory ApiException.networkError(Object error) {
    return ApiException(
      statusCode: 0,
      code: 'NETWORK_ERROR',
      message: 'Error de conexión: $error',
    );
  }

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final String _pathPrefix;
  final http.Client _client;
  final Duration _timeout;
  String? _accessToken;
  String? _refreshToken;

  ApiClient({
    required this.baseUrl,
    this._pathPrefix = '/api/v1',
    Duration timeout = const Duration(seconds: 10),
    http.Client? client,
  })  : _timeout = timeout,
        _client = client ?? http.Client();

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  bool get isAuthenticated => _accessToken != null;

  Map<String, String> get _headers => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final fullPath = path.startsWith(_pathPrefix) ? path : '$_pathPrefix$path';
    final uri = Uri.parse('$baseUrl$fullPath');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _attemptRefresh();
      if (refreshed) return {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiException.fromResponse(response);
  }

  Future<bool> _attemptRefresh() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _client
          .post(
            _uri('/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _accessToken = body['accessToken'] as String;
        return true;
      }
    } catch (_) {}
    clearTokens();
    return false;
  }

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? queryParams]) async {
    try {
      final response = await _client
          .get(_uri(path, queryParams), headers: _headers)
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .put(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  Future<Map<String, dynamic>> _delete(String path, [Map<String, String>? queryParams]) async {
    try {
      final response = await _client
          .delete(_uri(path, queryParams), headers: _headers)
          .timeout(_timeout);
      return await _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  // ── Auth ──

  Future<Map<String, dynamic>> login(String usuario, String password) async {
    final response = await _client
        .post(
          _uri('/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'usuario': usuario, 'password': password}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? body;
      _accessToken = data['accessToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      return body;
    }
    throw ApiException.fromResponse(response);
  }

  Future<Map<String, dynamic>> refresh() async {
    final response = await _client
        .post(
          _uri('/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': _refreshToken}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      _accessToken = body['accessToken'];
      return body;
    }
    clearTokens();
    throw ApiException.fromResponse(response);
  }

  // ── Agentes ──

  Future<Map<String, dynamic>> getAgentes({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    return _get('/agentes', params);
  }

  Future<Map<String, dynamic>> getAgenteById(int id) async {
    return _get('/agentes/$id');
  }

  Future<Map<String, dynamic>> getAgenteByLegajo(String legajo) async {
    return _get('/agentes/legajo/$legajo');
  }

  Future<Map<String, dynamic>> createAgente(Map<String, dynamic> agente) async {
    return _post('/agentes', agente);
  }

  Future<Map<String, dynamic>> updateAgente(
      int id, Map<String, dynamic> agente) async {
    return _put('/agentes/$id', agente);
  }

  Future<Map<String, dynamic>> deleteAgente(int id) async {
    return _delete('/agentes/$id');
  }

  // ── Controles de Alcoholemia ──

  Future<Map<String, dynamic>> getAlcoholemiasByAgente(int agenteId) async {
    return _get('/agentes/$agenteId/alcoholemias');
  }

  Future<Map<String, dynamic>> getAlcoholemias({
    String? fecha,
    String? desde,
    String? hasta,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (fecha != null) params['fecha'] = fecha;
    if (desde != null) params['desde'] = desde;
    if (hasta != null) params['hasta'] = hasta;
    if (search != null && search.isNotEmpty) params['search'] = search;
    return _get('/alcoholemias', params);
  }

  Future<Map<String, dynamic>> getReporteAlcoholemia({
    required String desde,
    required String hasta,
  }) async {
    return _get('/alcoholemias/reporte', {
      'desde': desde,
      'hasta': hasta,
    });
  }

  Future<Map<String, dynamic>> createAlcoholemia(
      int agenteId, Map<String, dynamic> control) async {
    return _post('/agentes/$agenteId/alcoholemias', control);
  }

  Future<Map<String, dynamic>> updateAlcoholemia(
      int id, Map<String, dynamic> control) async {
    return _put('/alcoholemias/$id', control);
  }

  Future<Map<String, dynamic>> deleteAlcoholemia(int id) async {
    return _delete('/alcoholemias/$id');
  }

  Future<Map<String, dynamic>> deleteAlcoholemiasByFecha(String fecha) async {
    return _delete('/alcoholemias', {'fecha': fecha});
  }

  // ── Observaciones / Reclamos ──

  Future<Map<String, dynamic>> getObservacionesByAgente(int agenteId) async {
    return _get('/agentes/$agenteId/observaciones');
  }

  Future<Map<String, dynamic>> getReporteAgente(int agenteId) async {
    return _get('/agentes/$agenteId/observaciones/reporte');
  }

  Future<Map<String, dynamic>> createObservacion(
      int agenteId, Map<String, dynamic> observacion) async {
    return _post('/agentes/$agenteId/observaciones', observacion);
  }

  Future<Map<String, dynamic>> updateObservacion(
      int id, Map<String, dynamic> observacion) async {
    return _put('/observaciones/$id', observacion);
  }

  Future<Map<String, dynamic>> deleteObservacion(int id) async {
    return _delete('/observaciones/$id');
  }

  // ── Sync ──

  Future<Map<String, dynamic>> syncPull(String lastSync) async {
    return _post('/sync/pull', {'lastSync': lastSync});
  }

  Future<Map<String, dynamic>> syncPush(Map<String, dynamic> changes) async {
    return _post('/sync/push', changes);
  }

  void dispose() {
    _client.close();
  }
}
