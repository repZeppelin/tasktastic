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
    // Ensure rank is fresh
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
                          _buildRankBadge(player.currentRank.toString()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // NEW: CLEARANCE INDICATOR
                      _buildClearanceBadge(player.isAdmin),
                      const SizedBox(height: 8),
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
            _buildSystemButtons(context, player),
          ],
        ),
      ),
    );
  }

  // --- NEW: CLEARANCE BADGE HELPER ---
  Widget _buildClearanceBadge(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFFF4444) : Colors.black,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        isAdmin ? "SYSTEM_ADMIN" : "PLAYER",
        style: TextStyle(
          color: isAdmin ? Colors.black : Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // --- UPDATED: SYSTEM BUTTONS WITH ADMIN GATING ---
  Widget _buildSystemButtons(BuildContext context, Player player) {
    return Column(
      children: [
        // ONLY VISIBLE IF ADMIN
        if (player.isAdmin) ...[
          _buildNoirButton(
            label: "AUDIT_FRAUD_LOGS",
            icon: Icons.gavel_sharp,
            color: Colors.black,
            onTap: () => NoirPopouts.showFraudLog(context),
          ),
          const SizedBox(height: 12),
        ],

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
            bool confirmed = await NoirPopouts.showConfirmAction(
              context,
              title: "Security Breach?",
              body: "ARE YOU SURE YOU WANT TO TERMINATE THE ACTIVE SESSION?",
            );

            if (confirmed) {
              if (context.mounted) {
                SessionManager.logoutOperative(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
    );
  }

  // --- EXISTING UI HELPERS ---

  Widget _buildRankBadge(String rank) {
    int rankValue = int.tryParse(rank.replaceAll('#', '')) ?? 100;
    Color rankColor = rankValue == 1 
        ? const Color(0xFFFFD700) 
        : rankValue <= 10 ? const Color(0xFF00E5FF) : Colors.grey[300]!;

    return Stack(
      children: [
        ClipPath(
          clipper: RankBadgeClipper(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            color: Colors.black,
            child: Text(rank, style: const TextStyle(fontSize: 11, color: Colors.transparent)),
          ),
        ),
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
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
          decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.black, width: 2)),
          child: const Icon(Icons.person_sharp, color: Colors.white, size: 40),
        ),
        Positioned(
          bottom: -8,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2)),
            child: Text(level, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("PROG_STATUS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              Text("$currentXP / $xpToNextLevel XP", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ],
          ),
        ),
        SizedBox(
          height: 14,
          child: Row(
            children: List.generate(totalSegments, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: ClipPath(
                    clipper: RankBadgeClipper(),
                    child: Container(color: index < filledSegments ? Colors.black : Colors.grey[300]),
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
          return _buildCondensedMarketCard(itemTemplate.name, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildCondensedMarketCard(String name, int count) {
    bool isPizza = name.toLowerCase().contains('pizza');
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
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
              color: isPizza ? const Color(0xFFFFE0B2) : const Color(0xFFFFCDD2),
              child: Icon(isPizza ? Icons.local_pizza : Icons.lunch_dining, size: 20),
            ),
          ),
          const Divider(height: 2, thickness: 2, color: Colors.black),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                if (count > 1) Text("x$count", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- BUTTON HELPER ---
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
      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black, offset: Offset(4, 4))]),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black, width: 2)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isColored ? Colors.white : Colors.black, letterSpacing: 1)),
            Icon(icon, size: 18, color: isColored ? Colors.white : Colors.black),
          ],
        ),
      ),
    ),
  );
}

// --- CLIPPERS ---
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
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}