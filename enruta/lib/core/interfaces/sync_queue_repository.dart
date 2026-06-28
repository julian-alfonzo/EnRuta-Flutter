abstract class SyncQueueRepository {
  Future<int> enqueueSync(String entidad, String operacion, int registroId, String payload);
  Future<List<Map<String, dynamic>>> getPendingSyncs();
  Future<int> getPendingSyncCount();
  Future<int> getFailedSyncCount();
  Future<List<int>> getFailedSyncIds();
  Future<void> deleteSyncItem(int id);
  Future<void> incrementSyncIntentos(int id);
  Future<void> markSyncFailed(int id);
  Future<void> markSyncPending(int id);
  Future<bool> hasPendingSyncForRecord(String entidad, int registroId);
}
