import '../../models/observacion_reclamo.dart';

abstract class ObservacionReclamoRepository {
  Future<List<ObservacionReclamo>> getObservacionesReclamosByAgente(int agenteId);
  Future<List<Map<String, dynamic>>> getObservacionesReporteByAgente(int agenteId);
  Future<int> insertObservacionReclamo(ObservacionReclamo observacion);
  Future<int> updateObservacionReclamo(ObservacionReclamo observacion);
  Future<int> deleteObservacionReclamo(int id);
}
