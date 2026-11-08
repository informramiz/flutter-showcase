import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_showcase/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fresh in-memory database, closed after the test.
AppDatabase memoryDatabase() {
  final database = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  return database;
}
