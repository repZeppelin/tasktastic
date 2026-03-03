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
  'lizard': Icons.pest_control_rodent_rounded, // Closest match for small reptile
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
  factory TaskTable() {
    return _instance;
  }

  Future<void> syncTasks() async {
    try {
      final userId = Player().id;
      if (userId == 0) return;

      // Map the taskList to a list of JSON objects
      final List<Map<String, dynamic>> jsonData = taskList
          .map((task) => task.toJson())
          .toList();

      await Supabase.instance.client
          .from('tasktastic')
          .update({'task_data': jsonData}) // Update the specific column
          .eq('user_id', userId);

      debugPrint(
        "DEBUG: [TASK_SYNC] Successfully uploaded/removed ${taskList.length} tasks.",
      );
    } catch (e) {
      debugPrint("DEBUG: [TASK_SYNC_ERROR] $e");
    }
  }

  Future<void> loadTasksFromSupabase() async {
    try {
      final userId = Player().id;
      if (userId == 0) return;

      debugPrint("DEBUG: [TASK_LOAD] Fetching mission data for ID: $userId...");

      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('task_data')
          .eq('user_id', userId)
          .single();

      final List<dynamic> remoteData = response['task_data'] ?? [];

      // Clear existing local list to prevent duplicates
      taskList.clear();

      for (var item in remoteData) {
        final Map<String, dynamic> taskMap = item as Map<String, dynamic>;

        // Convert JSON back into a Task object
        taskList.add(
          Task(
            id: taskMap['id'],
            name: taskMap['name'],
            description: taskMap['description'],
            difficulty: taskMap['difficulty'],
            deadline: DateTime.parse(taskMap['deadline']),
            createdAt: DateTime.parse(taskMap['created_at']),
            taskStatus: taskMap['status'],
          ),
        );
      }

      notifyListeners();
      debugPrint(
        "DEBUG: [TASK_LOAD] SUCCESS: ${taskList.length} tasks restored.",
      );
    } catch (e) {
      debugPrint(
        "DEBUG: [TASK_LOAD_ERROR] Failed to reconstruct task table: $e",
      );
    }
  }

  void addTask(
    String name,
    String description,
    int difficulty,
    DateTime deadline,
  ) {
    final newTask = Task(
      name: name,
      description: description,
      difficulty: difficulty,
      id: DateTime.now().millisecondsSinceEpoch, // Better ID than list length
      deadline: deadline,
    );
    taskList.add(newTask);
    notifyListeners();
    syncTasks(); // Sync to DB
  }

  void removeTask(int id) {
    taskList.removeWhere((task) => task.id == id);
    notifyListeners();
    syncTasks(); // Sync to DB
  }

  void nullifyTask(int id) {
    final task = taskList.firstWhere(
      (task) => task.id == id,
      orElse: () => throw Exception('Task with id $id not found'),
    );
    task.taskStatus = null;
    notifyListeners();
  }

  void falsifyTask(int id) {
    final task = taskList.firstWhere(
      (task) => task.id == id,
      orElse: () => throw Exception('Task with id $id not found'),
    );
    task.taskStatus = false;
    notifyListeners();
  }

  void truthifyTask(int id) {
    final task = taskList.firstWhere(
      (task) => task.id == id,
      orElse: () => throw Exception('Task with id $id not found'),
    );
    task.taskStatus = true;
    notifyListeners();
  }

  Task getTaskById(int id) {
    return taskList.firstWhere(
      (task) => task.id == id,
      orElse: () => throw Exception('Task with id $id not found'),
    );
  }

  int getTaskTableLength() {
    return taskList.length;
  }

  bool get hasTasksToFinalize => taskList.any((t) => t.taskStatus != null);

  Iterable<Task> iterateThroughTask() {
    return taskList.where((t) => t.taskStatus == false || t.taskStatus == true);
  }

  void removeFalseTrue(context) {
    for (var x in iterateThroughTask()) {
      switch (x.taskStatus) {
        case true:
          final amount = switch (x.difficulty) {
            3 => 100,
            2 => 50,
            1 => 25,
            _ => throw UnimplementedError(
              'Difficulty ${x.difficulty} not handled',
            ),
          };
          Player().add_to_wallet(amount);
          showTopSnackBar(context, '+$amount coins!', Colors.orange);
          break;
        case false:
          showBottomSnackBar(context, 'Gave up on task ${x.name}.', Colors.red);
          break;
        default:
      }
      (x.taskStatus);
    }
    taskList.removeWhere((t) => t.taskStatus == false || t.taskStatus == true);
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
      final userId = Player().id;
      if (userId == 0) return;

      await Supabase.instance.client
          .from('tasktastic')
          .update({'pet_data': existingPets.map((p) => p.toJson()).toList()})
          .eq('user_id', userId);
      debugPrint("DEBUG: [PET_SYNC] Vitals updated in cloud.");
    } catch (e) {
      debugPrint("DEBUG: [PET_SYNC_ERR] $e");
    }
  }

  // --- REFACTORED LOGIC ---

  void feedPet(Pet pet) {
    if (pet.foodLevel < 5) {
      pet.foodLevel++;
      if (pet.health < 5) pet.health++;
      notifyListeners();
      syncPets(); // Save new state
    }
  }

  void petThePet(Pet pet) {
    if (pet.health < 5) {
      pet.health++;
      notifyListeners();
      syncPets(); // Save new state
    }
  }

  void checkHungerForPets(BuildContext context) {
    bool stateChanged = false;
    for (var x in existingPets) {
      // Check if it's time for this specific pet to get hungry
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
      killPets(context); // This calls notifyListeners and syncPets
    }
  }

  void killPets(BuildContext context) {
    final originalCount = existingPets.length;
    existingPets.removeWhere((t) => t.health <= 0);

    if (existingPets.length < originalCount) {
      showTopSnackBar(context, "A pet has passed away.", Colors.red);
    }

    notifyListeners();
    syncPets(); // Finalize current state in DB
  }

  Future<void> loadPetsFromSupabase() async {
    try {
      final userId = Player().id;
      if (userId == 0) return;

      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('pet_data')
          .eq('user_id', userId)
          .single();

      final List<dynamic> remoteData = response['pet_data'] ?? [];

      existingPets = remoteData.map((p) => Pet.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("DEBUG: [PET_LOAD_ERROR] $e");
    }
  }

  void createNewPet(String name, int hungerRate, int petId) {
    // Check if pet already exists to prevent duplicates
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
  int id = 0000001;
  int level = 1;
  int currentRank = 0;
  int progression = 0; // This is your current XP
  int wallet_amount = 99999;
  Map<String, int> inventory = {};

  int get player_wallet_amount => wallet_amount;

  Future<int> getPlayerRank() async {
    try {
      if (id == 0) return 0;

      // 1. Fetch all players.
      // We order by level DESC (highest first), then xp_level DESC (most progress first)
      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('user_id, level, xp_level') // Fetch level and xp_level
          .order('level', ascending: false)
          .order('xp_level', ascending: false);

      final List<dynamic> leaderboard = response;

      // 2. Find the index of the current player (using their unique user_id)
      int rankIndex = leaderboard.indexWhere(
        (player) => player['user_id'] == id,
      );

      // If the player isn't found in the table, return 0 or a default
      if (rankIndex == -1) return 0;

      int actualRank = rankIndex + 1;

      debugPrint(
        "DEBUG: [RANK_SYSTEM] Player ID $id is RANK: $actualRank (Level: $level)",
      );
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

      debugPrint("DEBUG: [INV_LOAD] Accessing vault for ID: $id...");

      final response = await Supabase.instance.client
          .from('tasktastic')
          .select('inventory')
          .eq('user_id', id)
          .single();

      if (response['inventory'] != null) {
        // Cast the dynamic JSON map to Map<String, int>
        final Map<String, dynamic> remoteInv = response['inventory'];

        // We map the values to integers to ensure strict typing in Dart
        inventory = remoteInv.map((key, value) => MapEntry(key, value as int));

        notifyListeners();
        debugPrint(
          "DEBUG: [INV_LOAD] SUCCESS: ${inventory.length} unique items recovered.",
        );
      }
    } catch (e) {
      debugPrint("DEBUG: [INV_LOAD_ERROR] Failed to retrieve inventory: $e");
      // Initialize with empty map if fetch fails to prevent null crashes
      inventory = {};
      notifyListeners();
    }
  }

  Future<void> syncPlayerStats() async {
    try {
      if (id == 0) return; // Prevent syncing if user isn't logged in

      await Supabase.instance.client
          .from('tasktastic')
          .update({
            'money': wallet_amount,
            'xp_level': progression,
            'level': level,
            'inventory': inventory, // <--- NEW
          })
          .eq('user_id', id);

      debugPrint("DEBUG: [DB_SYNC] Data & Inventory uploaded.");
    } catch (e) {
      debugPrint("DEBUG: [DB_SYNC_ERROR] Sync failed: $e");
    }
  }

  // --- XP SYSTEM LOGIC ---

  /// Calculate required XP for the next level.
  /// Formula: Level * 100 (e.g., Lvl 1 needs 100, Lvl 2 needs 200)
  int get xpToNextLevel => level * 100;

  void addXP(BuildContext context, int amount) {
    progression += amount;

    // Check for level up loop (in case they gain massive XP at once)
    while (progression >= xpToNextLevel) {
      progression -= xpToNextLevel;
      level++;
      _triggerLevelUpUI(context);
    }
    syncPlayerStats();
    notifyListeners();
  }

  void _triggerLevelUpUI(BuildContext context) {
    // Using your custom Noir Popout
    NoirPopouts.showProtocolDialog(
      context,
      title: "LEVEL_UP_DETECTED",
      body:
          "System integrity increased to LEVEL $level.\nNew clearance codes generated.\n\nKeep pushing the network.",
      onConfirm: () {
        // Optional: Reward the player for leveling up
        add_to_wallet(level * 50);
        NoirPopouts.showToast(context, "CREDITS_BONUS_RELEASED");
      },
    );
  }

  // --- EXISTING METHODS ---

  void add_food(ShopItem item) {
    // If item exists, increment counter; otherwise, set to 1
    inventory[item.name] = (inventory[item.name] ?? 0) + 1;
    notifyListeners();
    syncPlayerStats();
  }

  void consumeFood(String itemName) {
    if (inventory.containsKey(itemName) && inventory[itemName]! > 0) {
      inventory[itemName] = inventory[itemName]! - 1;

      // Clean up the map if quantity hits zero
      if (inventory[itemName] == 0) {
        inventory.remove(itemName);
      }

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
