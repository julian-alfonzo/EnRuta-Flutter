import '../../models/control_alcoholemia.dart';

abstract class ControlAlcoholemiaRepository {
  Future<List<ControlAlcoholemia>> getControlesByAgente(int agenteId);
  Future<List<ControlAlcoholemia>> getControlesByFecha(String fecha);
  Future<List<ControlAlcoholemia>> getControlesEntreFechas(String desde, String hasta);
  Future<List<Map<String, dynamic>>> getControlesReporteEntreFechas(String desde, String hasta);
  Future<int> insertControl(ControlAlcoholemia control);
  Future<int> updateControl(ControlAlcoholemia control);
  Future<int> deleteControl(int id);
}
