import 'package:flutter/material.dart';
import 'package:finaltasktastic/scripts/data_handler.dart';

class SessionManager {
  /// BOOT SEQUENCE: Initializes all singletons with database data
  static Future<void> initializeOperativeSession(Map<String, dynamic> data) async {
    debugPrint("DEBUG: [SESSION_BOOT] Initializing systems...");

    // 1. Setup Player Core
    final player = Player();
    player.id = data['user_id'];
    player.name = data['username'] ?? "OPERATIVE";
    player.progression = data['xp_level'] ?? 0;
    player.wallet_amount = data['money'] ?? 0;
    player.level = data['level'] ?? 1;

    // 2. Load Sub-systems in parallel for speed
    await Future.wait([
      TaskTable().loadTasksFromSupabase(),
      player.loadInventoryFromSupabase(),
      PetHolder().loadPetsFromSupabase(),
    ]);

    // 3. Refresh UI
    player.notifyListeners();
    TaskTable().notifyListeners();
    PetHolder().notifyListeners();

    debugPrint("DEBUG: [SESSION_BOOT] All systems green for Operative: ${player.id}");
  }

  /// PURGE SEQUENCE: Clears all local data and returns app to "Cold" state
  static void logoutOperative(BuildContext context) {
    debugPrint("DEBUG: [SESSION_PURGE] Wiping local data cache...");

    // 1. Reset Player Singleton
    final player = Player();
    player.id = 0;
    player.name = "AGENT_00";
    player.level = 1;
    player.progression = 0;
    player.wallet_amount = 0;
    player.inventory = {};

    // 2. Reset TaskTable Singleton
    final taskTable = TaskTable();
    taskTable.taskList = [];

    // 3. Reset PetHolder Singleton
    final petHolder = PetHolder();
    petHolder.existingPets = [];
    petHolder.timeSinceLastUpdate = 0;

    // 4. Notify all listeners so UI updates to empty state
    player.notifyListeners();
    taskTable.notifyListeners();
    petHolder.notifyListeners();

    debugPrint("DEBUG: [SESSION_PURGE] Memory wipe complete.");
  }
}