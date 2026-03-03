import 'package:finaltasktastic/pages/main_page/settings_page.dart';
import 'package:finaltasktastic/scripts/datasync.dart';
import 'package:finaltasktastic/views/global_popouts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/pages/landing_page.dart';

class DrawerProfileHeader extends StatelessWidget {
  const DrawerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    Player().updateRank();
    final player = context.watch<Player>();

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER SECTION ---
            Row(
              children: [
                _buildAvatar("LVL ${player.level}"),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            player.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          // INTEGRATED: Dynamic Rank Badge
                          _buildRankBadge(Player().currentRank.toString()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildIconLabel(
                        Icons.account_balance_wallet_sharp,
                        "${player.wallet_amount} CC",
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildTacticalXP(player.progression, player.xpToNextLevel),

            const SizedBox(height: 32),

            // --- 2. INVENTORY SECTION ---
            _buildSectionLabel("INVENTORY: RATIONS", Icons.fastfood_sharp),
            const SizedBox(height: 12),
            _buildCondensedMarketIsland(player),

            const SizedBox(height: 32),

            // --- 3. SYSTEM ACTIONS ---
            _buildSystemButtons(context),
          ],
        ),
      ),
    );
  }

  // --- INTEGRATED DYNAMIC RANK BADGE ---

  Widget _buildRankBadge(String rank) {
    // Extract number for color logic
    int rankValue = int.tryParse(rank.replaceAll('#', '')) ?? 100;

    Color rankColor;
    if (rankValue == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rankValue <= 10) {
      rankColor = const Color(0xFF00E5FF); // Electric Cyan
    } else if (rankValue <= 50) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else {
      rankColor = Colors.grey[300]!; // Standard
    }

    return Stack(
      children: [
        // Hard Shadow Layer
        ClipPath(
          clipper: RankBadgeClipper(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            color: Colors.black,
            child: Text(
              rank,
              style: const TextStyle(fontSize: 11, color: Colors.transparent),
            ),
          ),
        ),
        // Main Content Layer
        Transform.translate(
          offset: const Offset(-2, -2),
          child: ClipPath(
            clipper: RankBadgeClipper(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: rankColor,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Text(
                rank,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- REFACTORED HELPERS ---

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String level) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const Icon(Icons.person_sharp, color: Colors.white, size: 40),
        ),
        Positioned(
          bottom: -8,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              level,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildTacticalXP(int currentXP, int xpToNextLevel) {
  const int totalSegments = 12;
  double ratio = xpToNextLevel > 0 ? (currentXP / xpToNextLevel) : 0;
  int filledSegments = (ratio * totalSegments).floor();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // --- NEW: XP TEXT OVERLAY ---
      Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "PROG_STATUS",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              "$currentXP / $xpToNextLevel XP",
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      // --- THE SEGMENTED BAR ---
      SizedBox(
        height: 14, // Slightly shorter for a sleeker look
        child: Row(
          children: List.generate(totalSegments, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: ClipPath(
                  clipper: RankBadgeClipper(),
                  child: Container(
                    color: index < filledSegments
                        ? Colors.black
                        : Colors.grey[300],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ],
  );
}

  Widget _buildCondensedMarketIsland(Player player) {
  if (player.inventory.isEmpty) return const Text("NO RATIONS");

  return SizedBox(
    height: 90,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: player.inventory.entries.map((entry) {
        final itemTemplate = ShopItem.findByName(entry.key);
        if (itemTemplate == null) return const SizedBox.shrink();

        return _buildCondensedMarketCard(
          itemTemplate.name, 
          entry.value, // This is your counter!
        );
      }).toList(),
    ),
  );
}

  Widget _buildCondensedMarketCard(String name, int count) {
    bool isPizza = name.toLowerCase().contains('pizza');
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: isPizza
                  ? const Color(0xFFFFE0B2)
                  : const Color(0xFFFFCDD2),
              child: Icon(
                isPizza ? Icons.local_pizza : Icons.lunch_dining,
                size: 20,
              ),
            ),
          ),
          const Divider(height: 2, thickness: 2, color: Colors.black),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (count > 1)
                  Text(
                    "x$count",
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemButtons(BuildContext context) {
    return Column(
      children: [
        _buildNoirButton(
          label: "SYSTEM SETTINGS",
          icon: Icons.settings_sharp,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
        const SizedBox(height: 12),
        _buildNoirButton(
          label: "TERMINATE SESSION",
          icon: Icons.power_settings_new_sharp,
          color: const Color(0xFFFF4444),
          onTap: () async {
            // 1. Trigger the tactical confirmation box
            bool confirmed = await NoirPopouts.showConfirmAction(
              context,
              title: "Security Breach?",
              body:
                  "ARE YOU SURE YOU WANT TO TERMINATE THE ACTIVE SESSION? ALL UNSAVED UPLINKS MAY BE LOST.",
            );

            // 2. Only proceed if the user tapped the confirm (check) button
            if (confirmed) {
              if (context.mounted) {
                SessionManager.logoutOperative(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
                NoirPopouts.showToast(context, "Logged out.");
              }
            }
          },
        ),
      ],
    );
  }
}

Widget _buildNoirButton({
  required String label,
  required IconData icon,
  required VoidCallback onTap,
  Color color = Colors.white,
}) {
  bool isColored = color != Colors.white;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isColored ? Colors.white : Colors.black,
                letterSpacing: 1,
              ),
            ),
            Icon(
              icon,
              size: 18,
              color: isColored ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    ),
  );
}

// --- CLIPPER FOR DIAGONAL SHAPES ---
class RankBadgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double slant = 8.0;
    path.moveTo(slant, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - slant, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Fixed: This must be named getClip
    Path path = Path();
    // Slant calculation
    double slantWidth = size.width * 0.3;

    path.moveTo(slantWidth, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width - slantWidth, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
