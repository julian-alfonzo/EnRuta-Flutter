import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:enruta/services/api_client.dart';

class MockClient extends Mock implements http.Client {}
class FakeUri extends Fake implements Uri {}

void main() {
  late MockClient mockClient;
  late ApiClient api;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockClient = MockClient();
    api = ApiClient(baseUrl: 'http://test.com', client: mockClient);
  });

  group('ApiClient construction', () {
    test('is not authenticated by default', () {
      expect(api.isAuthenticated, false);
    });

    test('setTokens enables auth', () {
      api.setTokens(accessToken: 'at', refreshToken: 'rt');
      expect(api.isAuthenticated, true);
    });

    test('clearTokens disables auth', () {
      api.setTokens(accessToken: 'at', refreshToken: 'rt');
      api.clearTokens();
      expect(api.isAuthenticated, false);
    });
  });

  group('Login', () {
    test('successful login stores tokens', () async {
      const responseBody = {
        'data': {
          'accessToken': 'access123',
          'refreshToken': 'refresh456',
          'rol': 'admin',
        }
      };

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await api.login('admin', 'admin123');
      expect(result['data']['accessToken'], 'access123');
      expect(api.isAuthenticated, true);
    });

    test('failed login throws ApiException', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"error":{"code":"UNAUTHORIZED","message":"Invalid"}}', 401));

      expect(() => api.login('admin', 'wrong'), throwsA(isA<ApiException>()));
    });

    test('network error throws on login', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Connection refused'));

      expect(() => api.login('admin', 'admin123'), throwsA(isA<Exception>()));
    });
  });

  group('Agentes endpoints', () {
    setUp(() {
      api.setTokens(accessToken: 'at', refreshToken: 'rt');
    });

    test('getAgentes returns list', () async {
      const responseBody = {
        'data': [
          {'id': 1, 'legajo': '001', 'apellidoNombre': 'Test', 'fechaIngreso': null, 'dependencia': null, 'cargo': null, 'turno': null, 'createdAt': '', 'updatedAt': ''}
        ],
        'meta': {'total': 1, 'page': 1, 'limit': 20}
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await api.getAgentes();
      expect(result['data'], isA<List>());
      expect((result['data'] as List).length, 1);
    });

    test('getAgentes with filters', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"data":[],"meta":{"total":0}}', 200));

      final result = await api.getAgentes(search: 'Perez', dependencia: 'Transito');
      expect(result['data'], isEmpty);
    });

    test('getAgenteByLegajo returns agent', () async {
      const responseBody = {
        'data': {'id': 1, 'legajo': '001', 'apellidoNombre': 'Test', 'fechaIngreso': null, 'dependencia': null, 'cargo': null, 'turno': null, 'createdAt': '', 'updatedAt': ''}
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await api.getAgenteByLegajo('001');
      expect(result['data']['legajo'], '001');
    });

    test('createAgente sends POST', () async {
      const responseBody = {
        'data': {'id': 99, 'legajo': 'NEW', 'apellidoNombre': 'New Agent'}
      };

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseBody), 201));

      final result = await api.createAgente({'legajo': 'NEW', 'apellidoNombre': 'New Agent'});
      expect(result['data']['id'], 99);
    });

    test('updateAgenteByLegajo sends PUT', () async {
      const responseBody = {
        'data': {'id': 1, 'legajo': '001', 'apellidoNombre': 'Updated'}
      };

      when(() => mockClient.put(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await api.updateAgenteByLegajo('001', {'apellidoNombre': 'Updated'});
      expect(result['data']['apellidoNombre'], 'Updated');
    });

    test('deleteAgenteByLegajo sends DELETE', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      final result = await api.deleteAgenteByLegajo('001');
      expect(result, isEmpty);
    });
  });

  group('Alcoholemias endpoints', () {
    setUp(() {
      api.setTokens(accessToken: 'at', refreshToken: 'rt');
    });

    test('getAlcoholemiasByLegajo', () async {
      const responseBody = {
        'data': [
          {'id': 1, 'agenteId': 1, 'fecha': '2025-06-21', 'resultado': 'Negativo', 'graduacion': null, 'servicioExtra': null, 'observacion': null, 'createdAt': ''}
        ]
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await api.getAlcoholemiasByLegajo('001');
      expect(result['data'], isA<List>());
    });

    test('createAlcoholemiaByLegajo', () async {
      const responseBody = {
        'data': {'id': 10, 'agenteId': 1, 'fecha': '2025-06-21', 'resultado': 'Negativo'}
      };

      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(responseBody), 201));

      final result = await api.createAlcoholemiaByLegajo('001', {'fecha': '2025-06-21', 'resultado': 'Negativo'});
      expect(result['data']['id'], 10);
    });

    test('getAlcoholemias with filters', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"data":[],"meta":{"total":0}}', 200));

      final result = await api.getAlcoholemias(desde: '2025-01-01', hasta: '2025-12-31');
      expect(result['data'], isEmpty);
    });

    test('getReporteAlcoholemia', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"data":[]}', 200));

      final result = await api.getReporteAlcoholemia(desde: '2025-01-01', hasta: '2025-12-31');
      expect(result['data'], isEmpty);
    });

    test('deleteAlcoholemia sends DELETE', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      final result = await api.deleteAlcoholemia(1);
      expect(result, isEmpty);
    });

    test('deleteAlcoholemiasByFecha', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      final result = await api.deleteAlcoholemiasByFecha('2025-06-21');
      expect(result, isEmpty);
    });
  });

  group('Observaciones endpoints', () {
    setUp(() {
      api.setTokens(accessToken: 'at', refreshToken: 'rt');
    });

    test('getObservacionesByLegajo', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"data":[]}', 200));

      final result = await api.getObservacionesByLegajo('001');
      expect(result['data'], isEmpty);
    });

    test('createObservacionByLegajo', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"data":{"id":1,"tipo":"Observación"}}', 201));

      final result = await api.createObservacionByLegajo('001', {'tipo': 'Observación', 'descripcion': 'Test', 'fecha': '2025-06-21'});
      expect(result['data']['tipo'], 'Observación');
    });

    test('getReporteAgenteByLegajo', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"data":[]}', 200));

      final result = await api.getReporteAgenteByLegajo('001');
      expect(result['data'], isEmpty);
    });

    test('updateObservacion', () async {
      when(() => mockClient.put(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"data":{"id":1}}', 200));

      final result = await api.updateObservacion(1, {'descripcion': 'Updated'});
      expect(result['data']['id'], 1);
    });

    test('deleteObservacion', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      final result = await api.deleteObservacion(1);
      expect(result, isEmpty);
    });
  });

  group('Sync endpoints', () {
    setUp(() {
      api.setTokens(accessToken: 'at', refreshToken: 'rt');
    });

    test('syncPull', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"data":{"agentes":[],"deleted":{"agentes":[]}}}', 200));

      final result = await api.syncPull('2025-01-01T00:00:00Z');
      expect(result['data']['agentes'], isEmpty);
    });

    test('syncPush', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"data":{"conflicts":[],"serverIds":{}}}', 200));

      final result = await api.syncPush({'agentes': {'created': []}});
      expect(result['data']['conflicts'], isEmpty);
    });
  });

  group('Error handling', () {
    setUp(() {
      api.setTokens(accessToken: 'at', refreshToken: 'rt');
    });

    test('GET returns ApiException on HTTP error', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"error":{"code":"NOT_FOUND","message":"X"}}', 404));

      expect(() => api.getAgenteByLegajo('NOPE'), throwsA(isA<ApiException>()));
    });

    test('POST returns ApiException on validation error', () async {
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"error":{"code":"VALIDATION_ERROR","message":"X","details":[{"field":"legajo","message":"required"}]}}', 400));

      try {
        await api.createAgente({});
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.code, 'VALIDATION_ERROR');
        expect(e.details!.length, 1);
      }
    });

    test('network error on GET', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('No connection'));

      try {
        await api.getAgentes();
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.code, 'NETWORK_ERROR');
      }
    });
  });

  group('ApiException', () {
    test('fromResponse with details', () {
      final response = http.Response(
        '{"error":{"code":"VALIDATION_ERROR","message":"Invalid","details":[{"field":"a","message":"b"}]}}',
        400,
      );
      final ex = ApiException.fromResponse(response);
      expect(ex.statusCode, 400);
      expect(ex.code, 'VALIDATION_ERROR');
      expect(ex.details, isNotNull);
      expect(ex.details!.length, 1);
    });

    test('fromResponse without body', () {
      final response = http.Response('not json', 500);
      final ex = ApiException.fromResponse(response);
      expect(ex.statusCode, 500);
    });

    test('networkError factory', () {
      final ex = ApiException.networkError('Test error');
      expect(ex.code, 'NETWORK_ERROR');
      expect(ex.statusCode, 0);
      expect(ex.toString(), contains('Test error'));
    });
  });

  group('Token refresh', () {
    test('refresh updates access token', () async {
      api.setTokens(accessToken: 'old', refreshToken: 'rt');
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"accessToken":"new_at"}', 200));

      final result = await api.refresh();
      expect(result['accessToken'], 'new_at');
    });

    test('refresh failure clears tokens', () async {
      api.setTokens(accessToken: 'old', refreshToken: 'rt');
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"error":{"code":"UNAUTHORIZED"}}', 401));

      try {
        await api.refresh();
        fail('should throw');
      } on ApiException {
        expect(api.isAuthenticated, false);
      }
    });

    test('auto-refresh on 401 for GET', () async {
      api.setTokens(accessToken: 'old', refreshToken: 'rt');
      var callCount = 0;
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
            callCount++;
            return http.Response('{"error":{"code":"UNAUTHORIZED"}}', 401);
          });
      when(() => mockClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('{"accessToken":"refreshed"}', 200));

      await api.getAgentes();
      expect(callCount, greaterThanOrEqualTo(1));
    });
  });
}
