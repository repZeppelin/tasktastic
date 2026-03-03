import 'package:finaltasktastic/views/snackbars.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finaltasktastic/scripts/data_handler.dart';

class PetHero extends StatefulWidget {
  const PetHero({super.key});

  @override
  State<PetHero> createState() => _PetHeroState();
}

class _PetHeroState extends State<PetHero> {
  final List<Widget> _particles = [];
  bool _isSelectingFood = false;

  /// Spawns the floating icon animation
  void _spawnParticle(IconData icon, Color color) {
    final Key particleKey = UniqueKey();
    setState(() {
      _particles.add(
        Positioned(
          top: 40,
          right: 40,
          key: particleKey,
          child: FloatingIcon(icon: icon, color: color),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _particles.removeWhere((p) => p.key == particleKey);
        });
      }
    });
  }

  void _openFoodInventory() {
    final player = Provider.of<Player>(context, listen: false);
    if (player.inventory.isEmpty) {
      showTopSnackBar(context, "NO RATIONS DETECTED", Colors.red[900]!);
      return;
    }
    setState(() => _isSelectingFood = true);
  }

  void _feedSelectedItem(ShopItem item, Pet pet) {
    final petHolder = Provider.of<PetHolder>(context, listen: false);
    final player = Provider.of<Player>(context, listen: false);

    petHolder.feedPet(pet);
    player.consumeFood(item.name);
    
    _spawnParticle(item.icon, item.accentColor);
    
    setState(() => _isSelectingFood = false);
    
    showTopSnackBar(
      context, 
      "FED ${item.name.toUpperCase()} (+${item.hungerRate} ENERGY)", 
      Colors.green[800]!
    );
  }

  @override
  Widget build(BuildContext context) {
    final petHolder = context.watch<PetHolder>();
    final player = context.watch<Player>();

    if (petHolder.existingPets.isEmpty) return const SizedBox.shrink();

    final pet = petHolder.existingPets.first;

    return Stack(
      children: [
        // --- BASE PET CARD ---
        Hero(
          tag: 'profile_hero',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _buildAvatar(pet.name),
                            const SizedBox(width: 14),
                            _buildPetStats(pet),
                          ],
                        ),
                      ),
                      _buildActionColumn(pet),
                    ],
                  ),
                ),
                _buildLabel(),
                ..._particles,
              ],
            ),
          ),
        ),

        // --- FULLSCREEN INVENTORY OVERLAY ---
        if (_isSelectingFood)
          _buildFullscreenInventory(player, pet),
      ],
    );
  }

  // --- FULLSCREEN INVENTORY LOGIC ---

  Widget _buildFullscreenInventory(Player player, Pet pet) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 20,
                left: 20,
                right: 20,
              ),
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("RATION_STASH", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: -1)),
                        Text("SELECT FUEL FOR ${pet.name.toUpperCase()}", 
                          style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isSelectingFood = false),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  )
                ],
              ),
            ),

            // INVENTORY LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: player.inventory.length,
                itemBuilder: (context, index) {
                  String itemName = player.inventory.keys.elementAt(index);
                  int quantity = player.inventory[itemName]!;
                  
                  final item = shopData
                      .expand((cat) => cat.items)
                      .firstWhere((i) => i.name == itemName, 
                        orElse: () => shopData[0].items[0]);

                  return GestureDetector(
                    onTap: () => _feedSelectedItem(item, pet),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: item.accentColor.withOpacity(0.1),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Icon(item.icon, color: item.accentColor, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(itemName.toUpperCase(), 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildTag("QTY: $quantity", Colors.black),
                                      const SizedBox(width: 6),
                                      _buildTag("+${item.hungerRate} ENERGY", Colors.green[800]!),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: color,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildAvatar(String petName) {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Image.network(
        'https://api.dicebear.com/7.x/pixel-art/png?seed=$petName',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPetStats(Pet pet) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pet.name.toUpperCase(), 
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 0.9, letterSpacing: -1.0)),
          const SizedBox(height: 4),
          Text("LVL. ${pet.level}", 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          _buildStatGroup(icon: Icons.fastfood, count: pet.foodLevel, activeColor: Colors.orange.shade800),
          const SizedBox(height: 4),
          _buildStatGroup(icon: Icons.favorite, count: pet.health, activeColor: Colors.red.shade800),
        ],
      ),
    );
  }

  Widget _buildActionColumn(Pet pet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSquareActionButton(
          icon: Icons.restaurant,
          backgroundColor: Colors.orange.shade800,
          onPressed: _openFoodInventory,
        ),
        const SizedBox(height: 10),
        _buildSquareActionButton(
          icon: Icons.favorite,
          backgroundColor: Colors.red.shade800,
          onPressed: () {
            context.read<PetHolder>().petThePet(pet);
            _spawnParticle(Icons.favorite, Colors.red);
          },
        ),
      ],
    );
  }

  Widget _buildLabel() {
    return Positioned(
      top: -12, left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        color: Colors.black,
        child: const Text("CURRENT COMPANION", 
          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildSquareActionButton({required IconData icon, required Color backgroundColor, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildStatGroup({required IconData icon, required int count, required Color activeColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 18, child: Icon(icon, size: 14, color: Colors.black)),
        const SizedBox(width: 6),
        ...List.generate(4, (index) => Container(
          width: 12, height: 12,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: index < count ? activeColor : Colors.white,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
        )),
      ],
    );
  }
}

// --- FLOATING ICON ANIMATION WIDGET ---

class FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const FloatingIcon({super.key, required this.icon, required this.color});

  @override
  State<FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<FloatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _movement;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(_controller);
    _movement = Tween<double>(begin: 0, end: -100).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _movement.value),
            child: Icon(widget.icon, color: widget.color, size: 40),
          ),
        );
      },
    );
  }
}