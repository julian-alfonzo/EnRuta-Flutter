abstract class SyncServiceInterface {
  Future<void> start();
  void stop();
  Future<void> fullSync();
  Future<void> pullFromServer();
  Future<void> enqueue(String entidad, String operacion, int registroId, Map<String, dynamic> payload);
  Future<void> processPendingSyncs();
  Future<int> get pendingCount;
  Future<int> get failedCount;
  Future<void> retryFailedItem(int id);
  Future<void> retryAllFailed();
}
