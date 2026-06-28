import '../../models/agente.dart';

abstract class AgenteRepository {
  Future<List<Agente>> getAgentes();
  Future<Agente?> getAgenteById(int id);
  Future<Agente?> getAgenteByLegajo(String legajo);
  Future<List<Agente>> buscarAgentes(String query);
  Future<int> insertAgente(Agente agente);
  Future<void> updateAgente(Agente agente);
  Future<void> deleteAgente(int id);
}
