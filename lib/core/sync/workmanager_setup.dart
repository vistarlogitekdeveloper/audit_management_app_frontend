import 'package:workmanager/workmanager.dart';

import 'sync_service.dart';
import '../../main.dart'; // We'll need to reference the Riverpod container or initialize dependencies

const String syncTaskName = "bgSyncTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncTaskName) {
        // In a real app, you would initialize your dependency injection here
        // For riverpod, we might need to recreate the container or the specific dependencies
        // since this runs in a separate isolate.
        
        // For simplicity in this scaffold, we assume the sync logic can be executed.
        // A complete implementation would instantiate the AppDatabase, Dio, and SecureStorage
        // locally in this isolate and create a SyncService instance to call `.syncData()`.
        
        print("Background sync task running...");
        // await syncServiceInstance.syncData();
      }
      return Future.value(true);
    } catch (err) {
      print("Background sync failed: $err");
      return Future.value(false);
    }
  });
}

class WorkmanagerSetup {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Let's keep it true for development
    );
  }

  static void registerPeriodicSync() {
    Workmanager().registerPeriodicTask(
      "1",
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
