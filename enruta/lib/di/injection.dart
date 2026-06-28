import 'package:get_it/get_it.dart';
import 'package:enruta/services/api_client.dart';
import 'package:enruta/services/api_service.dart';
import 'package:enruta/services/sync_service.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/core/interfaces/api_client_interface.dart';
import 'package:enruta/core/interfaces/sync_service_interface.dart';

final getIt = GetIt.instance;

void setupDependencyInjection({String baseUrl = 'https://enruta-msm.vercel.app'}) {
  // Database (singleton)
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // API Client
  getIt.registerLazySingleton<ApiClientInterface>(
    () => ApiClient(baseUrl: baseUrl),
  );

  // API Service (combines local DB + remote API)
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(
      baseUrl: baseUrl,
      apiClient: getIt<ApiClientInterface>(),
    ),
  );

  // Sync Service
  final syncService = SyncService();
  syncService.configure(getIt<ApiClientInterface>());
  getIt.registerLazySingleton<SyncServiceInterface>(() => syncService);
}

// Convenience getters for backward compatibility
ApiClientInterface get apiClient => getIt<ApiClientInterface>();
ApiService get apiService => getIt<ApiService>();
SyncServiceInterface get syncService => getIt<SyncServiceInterface>();
DatabaseHelper get databaseHelper => getIt<DatabaseHelper>();
