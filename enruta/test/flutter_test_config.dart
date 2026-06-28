import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/main.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.resetForTest();
  AppServices.init(baseUrl: 'http://localhost:3000');
  await testMain();
}
