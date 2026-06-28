import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/services/api_client.dart';

// NOTE: This integration test requires a running API server at localhost:3000.
// Run with: flutter test test/integration/api_integration_test.dart

void main() {
  const baseUrl = 'http://localhost:3000';

  group('API Integration Tests', () {
    late ApiClient api;
    String? accessToken;

    setUp(() {
      api = ApiClient(baseUrl: baseUrl);
    });

    test('POST /auth/login - login exitoso', () async {
      final response = await api.login('admin', 'admin123');
      expect(response['data'], isNotNull);
      final data = response['data'] as Map<String, dynamic>;
      expect(data['accessToken'], isNotNull);
      expect(data['refreshToken'], isNotNull);
      expect(data['expiresIn'], 3600);
      final usuario = data['usuario'] as Map<String, dynamic>;
      expect(usuario['usuario'], 'admin');
      expect(usuario['rol'], 'admin');
      accessToken = data['accessToken'] as String;
    });

    test('POST /auth/login - credenciales inválidas', () async {
      try {
        await api.login('ZZZ_NOEXISTE', '12345');
        fail('Debería lanzar ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
        expect(e.code, 'INVALID_CREDENTIALS');
      }
    });

    test('GET /agentes - listar (sin token)', () async {
      try {
        await api.getAgentes();
        fail('Debería requerir autenticación');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
        expect(e.code, 'UNAUTHORIZED');
      }
    });

    test('GET /agentes - con filtros dependencia/cargo', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.getAgentes(dependencia: 'Transito');
      final data = response['data'] as List;
      expect(data, isNotNull);
      expect(response['meta'], isNotNull);
    });

    test('GET /agentes/:id - obtener uno', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.getAgenteById(1);
      final data = response['data'] as Map<String, dynamic>;
      expect(data['id'], 1);
      expect(data['legajo'], isNotNull);
      expect(data['apellidoNombre'], isNotNull);
    });

    test('GET /agentes/legajo/:legajo', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.getAgenteByLegajo('63722');
      final data = response['data'] as Map<String, dynamic>;
      expect(data['legajo'], '63722');
    });

    test('CRUD agente completo', () async {
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final legajo = '98${ts.substring(ts.length - 3)}';

      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final create = await api.createAgente({
        'legajo': legajo,
        'apellidoNombre': 'Test $ts',
        'dependencia': 'Test Dept',
        'cargo': 'Test Cargo',
      });
      final created = create['data'] as Map<String, dynamic>;
      final newId = created['id'] as int;
      expect(created['legajo'], legajo);

      final updated = await api.updateAgente(newId, {
        'legajo': legajo,
        'apellidoNombre': 'Test Updated',
        'dependencia': 'Updated Dept',
      });
      final updatedData = updated['data'] as Map<String, dynamic>;
      expect(updatedData['apellidoNombre'], 'Test Updated');
      expect(updatedData['dependencia'], 'Updated Dept');

      final delete = await api.deleteAgente(newId);
      expect(delete.isEmpty, true);
    });

    test('GET /alcoholemias - buscar con rango de fechas', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.getAlcoholemias(
        desde: '2020-01-01',
        hasta: '2026-12-31',
      );
      final data = response['data'] as List?;
      expect(data, isNotNull);
      expect(response['meta'], isNotNull);
      // Debe incluir legajo y apellidoNombre del JOIN
      if (data!.isNotEmpty) {
        final first = data.first as Map<String, dynamic>;
        expect(first.containsKey('legajo'), isTrue);
        expect(first.containsKey('apellidoNombre'), isTrue);
      }
    });

    test('GET /alcoholemias - buscar con filtro dependencia', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.getAlcoholemias(dependencia: 'Transito');
      final data = response['data'] as List?;
      expect(data, isNotNull);
    });

    test('GET /alcoholemias - buscar con filtro dependencia', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.getAlcoholemias(dependencia: 'Transito');
      final data = response['data'] as List?;
      expect(data, isNotNull);
    });

    test('DELETE /alcoholemias?fecha - borrado masivo por dia', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.deleteAlcoholemiasByFecha('2099-12-31');
      expect(response.isEmpty, isTrue);
    });

    test('DELETE /alcoholemias?desde=&hasta= - borrado masivo por rango', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.deleteAlcoholemiasByRango('2099-01-01', '2099-01-31');
      expect(response.isEmpty, isTrue);
    });

    test('POST /sync/pull - sincronización', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.syncPull('2000-01-01T00:00:00Z');
      final data = response['data'] as Map<String, dynamic>;
      expect(data['agentes'], isNotNull);
      expect(data['alcoholemias'], isNotNull);
      expect(data['observaciones'], isNotNull);
      expect(data['serverTime'], isNotNull);
    });

    test('POST /sync/push - enviar cambios', () async {
      final login = await api.login('admin', 'admin123');
      final token = (login['data'] as Map)['accessToken'] as String;
      api.setTokens(accessToken: token, refreshToken: '');

      final response = await api.syncPush({
        'agentes': {
          'created': [],
          'updated': [],
        },
        'alcoholemias': {
          'created': [],
          'updated': [],
        },
        'observaciones': {
          'created': [],
          'updated': [],
        },
      });
      final data = response['data'] as Map<String, dynamic>;
      expect(data['conflicts'], isNotNull);
      expect(data['serverIds'], isNotNull);
    });
  });
}
