abstract class ApiClientInterface {
  bool get isAuthenticated;
  void setTokens({required String accessToken, required String refreshToken});
  void clearTokens();
  void dispose();

  Future<Map<String, dynamic>> login(String usuario, String password);
  Future<Map<String, dynamic>> refresh();

  Future<Map<String, dynamic>> getAgentes({String? search, String? dependencia, String? cargo, int page, int limit});
  Future<Map<String, dynamic>> getAgenteByLegajo(String legajo);
  Future<Map<String, dynamic>> createAgente(Map<String, dynamic> agente);
  Future<Map<String, dynamic>> updateAgenteByLegajo(String legajo, Map<String, dynamic> agente);
  Future<Map<String, dynamic>> deleteAgenteByLegajo(String legajo);

  Future<Map<String, dynamic>> getAlcoholemiasByLegajo(String legajo);
  Future<Map<String, dynamic>> createAlcoholemiaByLegajo(String legajo, Map<String, dynamic> control);
  Future<Map<String, dynamic>> getAlcoholemias({String? fecha, String? desde, String? hasta, String? search, String? dependencia, String? cargo, int page, int limit});
  Future<Map<String, dynamic>> getReporteAlcoholemia({required String desde, required String hasta});
  Future<Map<String, dynamic>> createAlcoholemia(int agenteId, Map<String, dynamic> control);
  Future<Map<String, dynamic>> updateAlcoholemia(int id, Map<String, dynamic> control);
  Future<Map<String, dynamic>> deleteAlcoholemia(int id);
  Future<Map<String, dynamic>> deleteAlcoholemiasByFecha(String fecha);
  Future<Map<String, dynamic>> deleteAlcoholemiasByRango(String desde, String hasta);

  Future<Map<String, dynamic>> getObservacionesByLegajo(String legajo);
  Future<Map<String, dynamic>> createObservacionByLegajo(String legajo, Map<String, dynamic> observacion);
  Future<Map<String, dynamic>> getReporteAgenteByLegajo(String legajo);
  Future<Map<String, dynamic>> createObservacion(int agenteId, Map<String, dynamic> observacion);
  Future<Map<String, dynamic>> updateObservacion(int id, Map<String, dynamic> observacion);
  Future<Map<String, dynamic>> deleteObservacion(int id);

  Future<Map<String, dynamic>> syncPull(String lastSync);
  Future<Map<String, dynamic>> syncPush(Map<String, dynamic> changes);
}
