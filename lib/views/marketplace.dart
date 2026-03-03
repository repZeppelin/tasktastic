import 'package:finaltasktastic/views/snackbars.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/views/marketplace_item_builder.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({super.key});

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  final TextEditingController _searchController = TextEditingController();
  
  ShopItem? _searchedItem;
  String _searchedCategory = "";
  List<Map<String, dynamic>> _searchResults = [];
  bool _isShowingResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC: PERFORMS THE SEARCH ---
  void _executeSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return;

    List<Map<String, dynamic>> matches = [];
    for (var cat in shopData) {
      for (var item in cat.items) {
        if (item.name.toLowerCase().contains(query)) {
          matches.add({'item': item, 'category': cat.title});
        }
      }
    }

    setState(() {
      _searchResults = matches;
      _isShowingResults = true;
    });
    FocusScope.of(context).unfocus();
  }

  // --- LOGIC: SELECT FROM GRID ---
  void _selectItemFromResult(ShopItem item, String category) {
    setState(() {
      _searchedItem = item;
      _searchedCategory = category;
      _isShowingResults = false; 
    });
  }

  // --- LOGIC: PURCHASE HANDLER ---
  void handlePurchase(ShopItem item, String categoryTitle, int quantity) {
    final player = Provider.of<Player>(context, listen: false);
    final int totalCost = item.price * quantity;

    if (player.wallet_amount >= totalCost) {
      String cleanTitle = categoryTitle.toLowerCase();
      
      if (cleanTitle.contains('pets')) {
        final petHolder = Provider.of<PetHolder>(context, listen: false);
        if (petHolder.existingPets.isEmpty) {
          // Use item.hungerRate as the base stat for the new pet
          petHolder.createNewPet(item.name, item.hungerRate, DateTime.now().millisecondsSinceEpoch);
        } else {
          showTopSnackBar(context, "MAX PET CAPACITY REACHED", Colors.red[900]!);
          return;
        }
      } else if (cleanTitle.contains('food')) {
        for (int i = 0; i < quantity; i++) {
          player.add_food(item);
        }
      }

      showTopSnackBar(context, "ACQUIRED: $quantity x ${item.name.toUpperCase()}", Colors.green[800]!);
      player.deduct_from_wallet(totalCost);
      setState(() => _searchedItem = null);
    } else {
      showTopSnackBar(context, "INSUFFICIENT FUNDS", Colors.red[900]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // --- BASE LAYER: MAIN SHOP LIST ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // SEARCH BAR
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
                      ),
                      child: const Text("MARKET", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _executeSearch(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: "SEARCH_ID...",
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _executeSearch,
                              child: Container(
                                width: 44, height: 44,
                                color: const Color(0xFF4CAF50),
                                child: const Icon(Icons.search, color: Colors.black, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.black, thickness: 3),
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
                      for (var categoryItem in shopData)
                        MarketSection(
                          category: categoryItem,
                          onSelect: (item) {
                            setState(() {
                              _searchedItem = item;
                              _searchedCategory = categoryItem.title;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- OVERLAY 1: SEARCH RESULTS WINDOW ---
          if (_isShowingResults)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("FOUND ${_searchResults.length} ENTITIES", 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () => setState(() => _isShowingResults = false),
                              )
                            ],
                          ),
                        ),
                        if (_searchResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text("NO DATA MATCHES SEARCH_ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          )
                        else
                          Flexible(
                            child: GridView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final res = _searchResults[index];
                                final ShopItem item = res['item'];
                                final String category = res['category'];

                                return GestureDetector(
                                  onTap: () => _selectItemFromResult(item, category),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 2),
                                      color: Colors.grey[50],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Fix: Use item.icon and item.accentColor
                                        Icon(item.icon, size: 32, color: item.accentColor),
                                        const SizedBox(height: 8),
                                        Text(item.name.toUpperCase(), 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(category.toUpperCase(), 
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 6),
                                        Text("\$${item.price}", style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // --- OVERLAY 2: FULLSCREEN ITEM DETAIL ---
          if (_searchedItem != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExpandedShopCard(
                          item: _searchedItem!,
                          onBuy: (qty) => handlePurchase(_searchedItem!, _searchedCategory, qty),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(() => _searchedItem = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.red, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                            ),
                            child: const Text("BACK_TO_MARKET", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}