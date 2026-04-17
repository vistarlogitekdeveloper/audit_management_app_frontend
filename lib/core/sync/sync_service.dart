import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../db/app_database.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import 'connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

part 'sync_service.g.dart';

class SyncService {
  final AppDatabase _db;
  final Dio _dio;
  final SecureStorage _storage;
  bool _isSyncing = false;

  SyncService(this._db, this._dio, this._storage);

  Future<void> syncData() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.any((r) => 
          r == ConnectivityResult.mobile || 
          r == ConnectivityResult.wifi || 
          r == ConnectivityResult.ethernet);
          
      if (!hasConnection) return;

      final deviceId = await _storage.getDeviceId();
      if (deviceId == null) return;

      // 1. Upload images first
      await _uploadPendingImages();

      // 2. Fetch pending records
      final pendingResponses = await (_db.select(_db.auditResponses)..where((t) => t.isSynced.equals(false))).get();
      final pendingActionPlans = await (_db.select(_db.actionPlans)..where((t) => t.isSynced.equals(false))).get();

      if (pendingResponses.isEmpty && pendingActionPlans.isEmpty) {
        return; // Nothing to sync
      }

      // 3. Prepare payload
      final payload = {
        "device_id": deviceId,
        "auditResponses": pendingResponses.map((e) => {
          "clientTempId": e.clientTempId,
          "deviceId": e.deviceId,
          "isDeleted": e.isDeleted,
          "updatedAt": e.updatedAt.toIso8601String(),
          "auditPlanId": e.auditPlanId,
          "questionId": e.questionId,
          "status": e.status,
          "remarks": e.remarks,
          "imagePath": e.imagePath,
        }).toList(),
        "actionPlans": pendingActionPlans.map((e) => {
          "clientTempId": e.clientTempId,
          "deviceId": e.deviceId,
          "isDeleted": e.isDeleted,
          "updatedAt": e.updatedAt.toIso8601String(),
          "auditResponseId": e.auditResponseId,
          "description": e.description,
          "assignedTo": e.assignedTo,
          "dueDate": e.dueDate?.toIso8601String(),
          "status": e.status,
        }).toList(),
      };

      // 4. Send Bulk Sync request
      final response = await _dio.post('/sync/bulk', data: payload);

      if (response.statusCode == 200) {
        final syncedIds = List<String>.from(response.data['synced'] ?? []);
        final failedIds = List<String>.from(response.data['failed'] ?? []);

        // 5. Update local database
        if (syncedIds.isNotEmpty) {
          await _db.transaction(() async {
            // Update AuditResponses
            await (_db.update(_db.auditResponses)
                  ..where((t) => t.clientTempId.isIn(syncedIds)))
                .write(const AuditResponsesCompanion(isSynced: Value(true)));

            // Update ActionPlans
            await (_db.update(_db.actionPlans)
                  ..where((t) => t.clientTempId.isIn(syncedIds)))
                .write(const ActionPlansCompanion(isSynced: Value(true)));
          });
        }
        
        // Log or handle failed ones if needed
        if (failedIds.isNotEmpty) {
          print('Sync partially failed for IDs: $failedIds');
        }
      }
    } catch (e) {
      print('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _uploadPendingImages() async {
    final pendingWithImages = await (_db.select(_db.auditResponses)
          ..where((t) => t.isSynced.equals(false))
          ..where((t) => t.imagePath.isNotNull()))
        .get();

    for (final record in pendingWithImages) {
      if (record.imagePath != null && !record.imagePath!.startsWith('http')) {
        // Image is a local file
        final file = File(record.imagePath!);
        if (await file.exists()) {
          try {
            final formData = FormData.fromMap({
              'file': await MultipartFile.fromFile(file.path),
            });

            final response = await _dio.post('/upload', data: formData);
            if (response.statusCode == 200 || response.statusCode == 201) {
              final String url = response.data['url'];
              
              // Update local DB with the remote URL
              await (_db.update(_db.auditResponses)
                    ..where((t) => t.clientTempId.equals(record.clientTempId)))
                  .write(AuditResponsesCompanion(imagePath: Value(url)));
            }
          } catch (e) {
            print('Image upload failed for ${record.clientTempId}: $e');
          }
        }
      }
    }
  }
}

@riverpod
SyncService syncService(SyncServiceRef ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioClientProvider).dio;
  final storage = ref.watch(secureStorageProvider);
  return SyncService(db, dio, storage);
}
