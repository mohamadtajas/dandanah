import 'dart:async';

import 'package:drift/drift.dart';

/// Shared test bootstrap. Tests intentionally open several in-memory databases;
/// that is safe because none of them share a query executor.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
