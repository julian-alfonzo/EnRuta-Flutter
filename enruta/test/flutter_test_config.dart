import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/di/injection.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.resetForTest();
  setupDependencyInjection(baseUrl: 'http://localhost:3000');
  await testMain();
}
