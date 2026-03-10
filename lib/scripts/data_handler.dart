import 'package:finaltasktastic/views/global_popouts.dart';
import 'package:finaltasktastic/views/snackbars.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

const Map<String, IconData> iconMapping = {
  // Food Items
  'pizza': Icons.local_pizza_rounded,
  'burger': Icons.lunch_dining_rounded,
  'taco': Icons.fastfood_rounded,
  'ramen': Icons.ramen_dining_rounded,
  'soda': Icons.local_drink_rounded,
  'coffee': Icons.coffee_rounded,
  'ice_cream': Icons.icecream_rounded,
  'sushi': Icons.set_meal_rounded,
  'hot_dog': Icons.bakery_dining_rounded,
  'donut': Icons.donut_large_rounded,

  // Pets
  'dog': Icons.pets_rounded,
  'cat': Icons.pets_rounded, // Use common pets icon
  'rabbit': Icons.cruelty_free_rounded,
  'parrot': Icons.flutter_dash_rounded, // Looks like a bird
  'lizard':
      Icons.pest_control_rodent_rounded, // Closest match for small reptile
  'hamster': Icons.catching_pokemon, // Round/small vibe
  'owl': Icons.visibility_rounded, // Observation theme
  'turtle': Icons.slow_motion_video_rounded, // Abstract shell vibe
  'pig': Icons.savings_rounded, // Piggy bank icon
  'ferret': Icons.directions_run_rounded, // Agile vibe
};

List<ShopCategory> shopData = [];

// 2. Create the loader function
Future<void> initMarketplace() async {
  try {
    final String response = await rootBundle.loadString(
      'lib/data/shop_data.json',
    );
    final List<dynamic> data = json.decode(response);

    shopData = data
        .map((categoryJson) => ShopCategory.fromJson(categoryJson))
        .toList();
    print("MARKET_PROTOCOLS: LOAD_SUCCESSFUL");
  } catch (e) {
    print("MARKET_PROTOCOLS: LOAD_FAILED -> $e");
  }
}

class Task {
  final String name;
  final String description;
  final int difficulty;
  final int id;
  final DateTime createdAt;
  final DateTime deadline;
  bool? taskStatus;

  Task({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.id,
    required this.deadline,
    DateTime? createdAt,
    this.taskStatus,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Supabase JSONB
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'difficulty': difficulty,
    'deadline': deadline.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'status': taskStatus,
  };
}

class TaskTable extends ChangeNotifier {
  List<Task> taskList = [];
  
  TaskTable._privateConstructor();
  static final TaskTable _instance = TaskTable._privateConstructor();
  factory TaskTable() => _instance;

  // --- INTERNAL HELPER: DATABASE UPLINK ---

  Future<void> _appendToHistory({
    required String taskName,
    required int coinAmount,
    required bool isFraudulent,
    required bool payoutStatus,
  }) async {
    try {
      final int searchId = Player().id;
      if (searchId == 0) return;

      // Safety check: Retrieve current history using dual-ID check
      final List<dynamic> data = await Supabase.instance.client
          .from('tasktastic')
          .select('task_history')
          .or('id.eq.$searchId,user_id.eq.$searchId');

      if (data.isEmpty) {
        debugPrint("DEBUG: [SYS_ERR] ID $searchId NOT FOUND IN DATABASE");
        return;
      }

      List<dynamic> currentHistory = data[0]['task_history'] != null
          ? List.from(data[0]['task_history'])
          : [];

      currentHistory.add({
        'title': taskName,
        'coins': coinAmount,
        'is_suspicious': isFraudulent,
        'is_paid': payoutStatus,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update using same dual-ID pattern
      await Supabase.instance.client
          .from('tasktastic')
          .update({'task_history': currentHistory})
          .or('id.eq.$searchId,user_id.eq.$searchId');

      debugPrint("DEBUG: [SYS_UPLINK] SUCCESS_FOR_ID_$searchId");
    } catch (e) {
      debugPrint("DEBUG: [SYS_CRITICAL_FAILURE] -> $e");
    }
  }

  // --- PUBLIC MISSION DATA METHODS ---

  Future<void> syncTasks() async {
  final int searchId = Player().id;
  debugPrint("DEBUG: [SYNC_INIT] Preparing upload for ID: $searchId");

  if (searchId == 0) {
    debugPrint("DEBUG: [SYNC_ABORT] No active Operative ID found. Sync cancelled.");
    return;
  }

  try {
    // Checkpoint 1: Mapping Data
    final List<Map<String, dynamic>> jsonData = taskList.map((task) {
      final json = task.toJson();
      // REMOVED: json.remove('description'); 
      // The description is now preserved in the payload.
      return json;
    }).toList();

    debugPrint("DEBUG: [SYNC_PAYLOAD_READY] ${jsonData.length} tasks serialized.");

    // Checkpoint 2: Database Update
    final response = await Supabase.instance.client
        .from('tasktastic')
        .update({'task_data': jsonData})
        .or('id.eq.$searchId,user_id.eq.$searchId')
        .select(); // Calling .select() confirms what was actually written

    if (response != null) {
      debugPrint("DEBUG: [SYNC_SUCCESS] Database updated for ID: $searchId");
    } else {
      debugPrint("DEBUG: [SYNC_WARNING] Update executed but returned no confirmation.");
    }

  } catch (e) {
    // Checkpoint 3: Critical Failure
    debugPrint("DEBUG: [SYNC_CRITICAL_ERROR] -> $e");
  }
}

  Future<void> loadTasksFromSupabase() async {
  final int searchId = Player().id;
  debugPrint("DEBUG: [RECOVERY_INIT] Attempting task retrieval for ID: $searchId");

  if (searchId == 0) {
    debugPrint("DEBUG: [RECOVERY_ABORT] No active Operative ID found.");
    return;
  }

  try {
    // Checkpoint 1: Database Request
    final response = await Supabase.instance.client
        .from('tasktastic')
        .select('task_data')
        .or('id.eq.$searchId,user_id.eq.$searchId')
        .maybeSingle();

    if (response == null) {
      debugPrint("DEBUG: [RECOVERY_VOID] No database row exists for ID: $searchId");
      return;
    }

    final dynamic rawData = response['task_data'];
    if (rawData == null) {
      debugPrint("DEBUG: [RECOVERY_EMPTY] task_data column is NULL in database.");
      taskList.clear();
      notifyListeners();
      return;
    }

    final List<dynamic> remoteData = rawData;
    debugPrint("DEBUG: [RECOVERY_DATA_FOUND] Processing ${remoteData.length} entries...");

    taskList.clear();

    for (int i = 0; i < remoteData.length; i++) {
      try {
        final Map<String, dynamic> taskMap = remoteData[i] as Map<String, dynamic>;
        
        // Checkpoint 2: Individual Field Validation
        // We use ?? (null-coalescing) to prevent the "Null is not a subtype of String" crash
        final String tName = taskMap['name'] ?? "UNKNOWN_NAME";
        final String tDesc = taskMap['description'] ?? "REDACTED_OR_MISSING";
        final int tDiff = taskMap['difficulty'] ?? 1;
        final String? tDeadlineRaw = taskMap['deadline'];
        final String? tCreatedRaw = taskMap['created_at'];

        taskList.add(Task(
          id: taskMap['id'] ?? DateTime.now().millisecondsSinceEpoch + i,
          name: tName,
          description: tDesc,
          difficulty: tDiff,
          deadline: tDeadlineRaw != null ? DateTime.parse(tDeadlineRaw) : DateTime.now(),
          createdAt: tCreatedRaw != null ? DateTime.parse(tCreatedRaw) : DateTime.now(),
          taskStatus: taskMap['status'], // bool? allows null
        ));

        debugPrint("DEBUG: [RECOVERY_SUCCESS] Task '$tName' restored.");
      } catch (itemErr) {
        debugPrint("DEBUG: [RECOVERY_ITEM_FAIL] Entry #$i failed: $itemErr");
        // We continue the loop so one bad task doesn't hide all the others
      }
    }

    notifyListeners();
    debugPrint("DEBUG: [RECOVERY_COMPLETE] Total Tasks Restored: ${taskList.length}");

  } catch (e) {
    // Checkpoint 3: Critical System Failure
    debugPrint("DEBUG: [SYS_CRITICAL_RECOVERY_FAILURE] -> $e");
  }
}
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final int searchId = Player().id;
    if (searchId == 0) return [];

    try {
      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('task_history')
          .or('id.eq.$searchId,user_id.eq.$searchId')
          .maybeSingle();

      if (response == null || response['task_history'] == null) return [];

      final List<dynamic> history = response['task_history'];
      return history.whereType<Map<String, dynamic>>().where((entry) {
        final bool isSuspicious = entry['is_suspicious'] ?? false;
        final bool isPaid = entry['is_paid'] ?? false;
        return isSuspicious || (!isSuspicious && !isPaid);
      }).toList();
    } catch (e) {
      debugPrint("TERMINAL_ERROR: FAILED_TO_FETCH_AUDIT_LOGS -> $e");
      return [];
    }
  }

  Future<int> claimValidRewards() async {
    try {
      final player = Player();
      final int searchId = player.id;

      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('task_history')
          .or('id.eq.$searchId,user_id.eq.$searchId')
          .single();

      final dynamic historyData = response['task_history'];
      if (historyData == null || historyData is! List) return 0;

      List<dynamic> history = List.from(historyData);
      int totalToClaim = 0;
      bool hasChanges = false;

      for (var entry in history) {
        if (entry is Map<String, dynamic>) {
          if (entry['is_suspicious'] == false && entry['is_paid'] == false) {
            totalToClaim += (entry['coins'] as num).toInt();
            entry['is_paid'] = true;
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        await Supabase.instance.client
            .from('tasktastic')
            .update({'task_history': history})
            .or('id.eq.$searchId,user_id.eq.$searchId');

        player.add_to_wallet(totalToClaim);
      }

      return totalToClaim;
    } catch (e) {
      debugPrint("CLAIM_PROTOCOL_FAILURE: $e");
      return 0;
    }
  }

  Future<void> approveFraudulentTask(int dbId, Map<String, dynamic> targetTask) async {
    try {
      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('task_history')
          .or('id.eq.$dbId,user_id.eq.$dbId')
          .single();

      List<dynamic> history = response['task_history'] ?? [];

      for (var task in history) {
        if (task['title'] == targetTask['title'] &&
            task['timestamp'] == targetTask['timestamp']) {
          task['is_suspicious'] = false;
        }
      }

      await Supabase.instance.client
          .from('tasktastic')
          .update({'task_history': history})
          .or('id.eq.$dbId,user_id.eq.$dbId');
    } catch (e) {
      debugPrint("AUDIT_RECON_FAILURE: $e");
    }
  }

  // --- LOCAL STATE MANAGEMENT ---

  void addTask(String name, String description, int difficulty, DateTime deadline) {
    final newTask = Task(
      name: name,
      description: description,
      difficulty: difficulty,
      id: DateTime.now().millisecondsSinceEpoch,
      deadline: deadline,
    );
    taskList.add(newTask);
    notifyListeners();
    syncTasks();
  }

  void removeTask(int id) {
    taskList.removeWhere((task) => task.id == id);
    notifyListeners();
    syncTasks();
  }

  void nullifyTask(int id) {
    getTaskById(id).taskStatus = null;
    notifyListeners();
  }

  void falsifyTask(int id) {
    getTaskById(id).taskStatus = false;
    notifyListeners();
  }

  void truthifyTask(int id) {
    getTaskById(id).taskStatus = true;
    notifyListeners();
  }

  Task getTaskById(int id) => taskList.firstWhere((t) => t.id == id);

  int getTaskTableLength() => taskList.length;

  bool get hasTasksToFinalize => taskList.any((t) => t.taskStatus != null);

  Iterable<Task> iterateThroughTask() {
    return taskList.where((t) => t.taskStatus != null);
  }

  bool isTaskFraudulent(dynamic task) {
    final duration = DateTime.now().difference(task.createdAt).inMinutes;
    return duration < 2;
  }

  void removeFalseTrue(BuildContext context) async {
    for (var x in iterateThroughTask().toList()) {
      if (x.taskStatus == true) {
        final bool isFraud = isTaskFraudulent(x);
        final bool rewardsPaid = !isFraud;

        final int amount = switch (x.difficulty) {
          3 => 100,
          2 => 50,
          1 => 25,
          _ => 0,
        };

        await _appendToHistory(
          taskName: x.name,
          coinAmount: amount,
          isFraudulent: isFraud,
          payoutStatus: rewardsPaid,
        );

        if (rewardsPaid) {
          Player().add_to_wallet(amount);
          showTopSnackBar(context, '+$amount CC RECEIVED', Colors.orange);
        } else {
          showTopSnackBar(context, 'PAYOUT_WITHHELD: SECURITY_BREACH', const Color(0xFFB71C1C));
          NoirPopouts.triggerRandomFeedback(context, "FRAUD_DETECTED");
        }
      } else if (x.taskStatus == false) {
        showBottomSnackBar(context, 'TASK ABANDONED: ${x.name}', Colors.red);
      }
    }

    taskList.removeWhere((t) => t.taskStatus != null);
    syncTasks();
  }
}

class PetHolder with ChangeNotifier {
  List<Pet> existingPets = [];
  int timeSinceLastUpdate = 0;

  PetHolder._privateConstructor();
  static final PetHolder _instance = PetHolder._privateConstructor();
  factory PetHolder() => _instance;

  // --- DATABASE SYNC ---
  Future<void> syncPets() async {
    try {
      final int searchId = Player().id;
      if (searchId == 0) return;

      await Supabase.instance.client
          .from('tasktastic')
          .update({'pet_data': existingPets.map((p) => p.toJson()).toList()})
          .or('id.eq.$searchId,user_id.eq.$searchId'); // Dual-ID Safety
          
      debugPrint("DEBUG: [PET_SYNC] Vitals updated in cloud.");
    } catch (e) {
      debugPrint("DEBUG: [PET_SYNC_ERR] $e");
    }
  }

  Future<void> loadPetsFromSupabase() async {
    try {
      final int searchId = Player().id;
      if (searchId == 0) return;

      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('pet_data')
          .or('id.eq.$searchId,user_id.eq.$searchId') // Dual-ID Safety
          .single();

      final List<dynamic> remoteData = response['pet_data'] ?? [];

      existingPets = remoteData.map((p) => Pet.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("DEBUG: [PET_LOAD_ERROR] $e");
    }
  }

  // --- LOGIC ---

  void feedPet(Pet pet) {
    if (pet.foodLevel < 5) {
      pet.foodLevel++;
      if (pet.health < 5) pet.health++;
      notifyListeners();
      syncPets();
    }
  }

  void petThePet(Pet pet) {
    if (pet.health < 5) {
      pet.health++;
      notifyListeners();
      syncPets();
    }
  }

  void checkHungerForPets(BuildContext context) {
    bool stateChanged = false;
    for (var x in existingPets) {
      if (timeSinceLastUpdate % x.elapsedTimeHungerIncrease == 0) {
        if (x.foodLevel <= 0) {
          if (x.health > 0) {
            x.health--;
            stateChanged = true;
          }
        } else {
          x.foodLevel--;
          stateChanged = true;
        }
      }
    }

    if (stateChanged) {
      killPets(context);
    }
  }

  void killPets(BuildContext context) {
    final originalCount = existingPets.length;
    existingPets.removeWhere((t) => t.health <= 0);

    if (existingPets.length < originalCount) {
      showTopSnackBar(context, "A pet has passed away.", Colors.red);
    }

    notifyListeners();
    syncPets();
  }

  void createNewPet(String name, int hungerRate, int petId) {
    if (!existingPets.any((p) => p.petId == petId)) {
      existingPets.add(
        Pet(name: name, elapsedTimeHungerIncrease: hungerRate, petId: petId),
      );
      notifyListeners();
      syncPets();
    }
  }
}

class Pet {
  final String name;
  int petId;
  int level = 0;
  int health = 5;
  int foodLevel = 5;
  final int elapsedTimeHungerIncrease;

  Pet({
    required this.name,
    required this.elapsedTimeHungerIncrease,
    required this.petId,
    this.level = 0,
    this.health = 5,
    this.foodLevel = 5,
  });

  // Convert to Map for Supabase JSONB
  Map<String, dynamic> toJson() => {
    'name': name,
    'pet_id': petId,
    'level': level,
    'health': health,
    'food_level': foodLevel,
    'hunger_rate': elapsedTimeHungerIncrease,
  };

  // Factory to create a Pet from Supabase data
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      name: json['name'],
      petId: json['pet_id'],
      level: json['level'],
      health: json['health'],
      foodLevel: json['food_level'],
      elapsedTimeHungerIncrease: json['hunger_rate'],
    );
  }
}

class PlayerHandler {
  PlayerHandler._privateconstructor();
  static final PlayerHandler _maininstance =
      PlayerHandler._privateconstructor();
  List<Player> players = [];
  factory PlayerHandler() {
    return _maininstance;
  }
}

class Player with ChangeNotifier {
  Player._privateConstructor();
  static final Player _player = Player._privateConstructor();
  factory Player() => _player;

  String name = "AGENT_00";
  bool isAdmin = false;
  int id = 0000001;
  int level = 1;
  int currentRank = 0;
  int progression = 0; 
  int wallet_amount = 99999;
  Map<String, int> inventory = {};

  int get player_wallet_amount => wallet_amount;

  // --- DATABASE & RANKING ---

  Future<int> getPlayerRank() async {
    try {
      if (id == 0) return 0;

      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('id, user_id, level, xp_level') // Select both ID columns
          .order('level', ascending: false)
          .order('xp_level', ascending: false);

      final List<dynamic> leaderboard = response;

      // Check both id and user_id for rank matching
      int rankIndex = leaderboard.indexWhere(
        (player) => player['id'] == id || player['user_id'] == id,
      );

      if (rankIndex == -1) return 0;

      int actualRank = rankIndex + 1;
      debugPrint("DEBUG: [RANK_SYSTEM] Player ID $id is RANK: $actualRank");
      return actualRank;
    } catch (e) {
      debugPrint("DEBUG: [RANK_ERROR] Calculation failed: $e");
      return 0;
    }
  }

  Future<void> updateRank() async {
    currentRank = await getPlayerRank();
    notifyListeners();
  }

  Future<void> loadInventoryFromSupabase() async {
    try {
      if (id == 0) return;

      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('inventory')
          .or('id.eq.$id,user_id.eq.$id') // Dual-ID Safety
          .single();

      if (response['inventory'] != null) {
        final Map<String, dynamic> remoteInv = response['inventory'];
        inventory = remoteInv.map((key, value) => MapEntry(key, value as int));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("DEBUG: [INV_LOAD_ERROR] $e");
      inventory = {};
      notifyListeners();
    }
  }

  Future<void> syncPlayerStats() async {
    try {
      if (id == 0) return;

      await Supabase.instance.client
          .from('tasktastic')
          .update({
            'money': wallet_amount,
            'xp_level': progression,
            'level': level,
            'inventory': inventory,
          })
          .or('id.eq.$id,user_id.eq.$id'); // Dual-ID Safety

      debugPrint("DEBUG: [DB_SYNC] Data & Inventory uploaded.");
    } catch (e) {
      debugPrint("DEBUG: [DB_SYNC_ERROR] $e");
    }
  }

  // --- XP & REWARDS ---

  int get xpToNextLevel => level * 100;

  void addXP(BuildContext context, int amount) {
    progression += amount;
    while (progression >= xpToNextLevel) {
      progression -= xpToNextLevel;
      level++;
      _triggerLevelUpUI(context);
    }
    syncPlayerStats();
    notifyListeners();
  }

  void _triggerLevelUpUI(BuildContext context) {
    NoirPopouts.showProtocolDialog(
      context,
      title: "LEVEL_UP_DETECTED",
      body: "System integrity increased to LEVEL $level.\nNew clearance codes generated.",
      onConfirm: () {
        add_to_wallet(level * 50);
      },
    );
  }

  // --- INVENTORY & WALLET ---

  void add_food(ShopItem item) {
    inventory[item.name] = (inventory[item.name] ?? 0) + 1;
    notifyListeners();
    syncPlayerStats();
  }

  void consumeFood(String itemName) {
    if (inventory.containsKey(itemName) && inventory[itemName]! > 0) {
      inventory[itemName] = inventory[itemName]! - 1;
      if (inventory[itemName] == 0) inventory.remove(itemName);
      notifyListeners();
      syncPlayerStats();
    }
  }

  void add_to_wallet(int value) {
    wallet_amount += value;
    notifyListeners();
    syncPlayerStats();
  }

  void deduct_from_wallet(int value) {
    if (wallet_amount >= value) {
      wallet_amount -= value;
      notifyListeners();
      syncPlayerStats();
    }
  }
}
class ShopCategory {
  final String title;
  final List<ShopItem> items;

  ShopCategory({required this.title, required this.items});

  // Factory to build the category and its nested items
  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List;
    List<ShopItem> itemObjects = list.map((i) => ShopItem.fromJson(i)).toList();

    return ShopCategory(
      title: json['title'] ?? "UNKNOWN_SECTION",
      items: itemObjects,
    );
  }
}

class ShopItem {
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color accentColor;
  final int hungerRate; // <--- NEW FIELD

  ShopItem({
    required this.name,
    this.description = "NO_DATA_AVAILABLE_IN_ARCHIVES",
    required this.price,
    required this.icon,
    required this.accentColor,
    this.hungerRate = 10, // Default fallback
  });

  static ShopItem? findByName(String name) {
    // This assumes shopData is a global list or accessible in this scope
    for (var category in shopData) {
      for (var item in category.items) {
        if (item.name.toLowerCase().trim() == name.toLowerCase().trim()) {
          return item;
        }
      }
    }
    return null; // Returns null if no match is found
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      name: json['name'],
      description: json['description'],
      price: json['price'],
      // This is the fix: look up the string name in our safe map
      icon: iconMapping[json['icon_name']] ?? Icons.help_outline,
      accentColor: Color(json['accent_hex']),
      hungerRate: json['hunger_rate'] ?? 10,
    );
  }
}
