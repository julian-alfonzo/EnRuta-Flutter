import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:enruta/database/database_helper.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseHelper.enableTestMode();
  await DatabaseHelper.resetForTest();
  await testMain();
}
