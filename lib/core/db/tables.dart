import 'package:drift/drift.dart';

abstract class OfflineSyncTable extends Table {
  TextColumn get clientTempId => text()(); // UUID v4
  TextColumn get deviceId => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('AuditPlan')
class AuditPlans extends OfflineSyncTable {
  TextColumn get id => text().nullable()(); // Server ID
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {clientTempId};
}

@DataClassName('AuditQuestion')
class AuditQuestions extends OfflineSyncTable {
  TextColumn get id => text().nullable()(); // Server ID
  TextColumn get auditPlanId => text()(); // Server or Client Temp ID reference
  TextColumn get questionText => text()();
  TextColumn get category => text()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientTempId};
}

@DataClassName('AuditResponse')
class AuditResponses extends OfflineSyncTable {
  TextColumn get id => text().nullable()(); // Server ID
  TextColumn get auditPlanId => text()();
  TextColumn get questionId => text()();
  TextColumn get status => text()(); // PASS, FAIL, NA
  TextColumn get remarks => text().nullable()();
  TextColumn get imagePath => text().nullable()(); // Local path initially, URL after sync

  @override
  Set<Column> get primaryKey => {clientTempId};
}

@DataClassName('ActionPlan')
class ActionPlans extends OfflineSyncTable {
  TextColumn get id => text().nullable()(); // Server ID
  TextColumn get auditResponseId => text()();
  TextColumn get description => text()();
  TextColumn get assignedTo => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status => text()(); // PENDING, IN_PROGRESS, COMPLETED

  @override
  Set<Column> get primaryKey => {clientTempId};
}
