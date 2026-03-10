import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:finaltasktastic/views/ProfileDrawer.dart';
import 'package:finaltasktastic/views/homepage.dart';
import 'package:finaltasktastic/views/marketplace.dart';
import 'package:finaltasktastic/views/secret.dart'; 
import 'package:finaltasktastic/views/login_animation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;
  Timer? _periodicTimer;
  bool _showWelcome = true;

  List<Widget> _getPages(bool isAdmin) {
    return [
      const Homepage(),
      const Marketplace(),
      if (isAdmin) const GlobalAuditPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      PetHolder().checkHungerForPets(context);
      PetHolder().timeSinceLastUpdate++;
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index && !_isDrawerOpen) {
      setState(() => _selectedIndex = index);
    }
  }

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<Player>();
    final bool isAdmin = player.isAdmin;
    final List<Widget> pages = _getPages(isAdmin);

    return Scaffold(
      backgroundColor: const Color(0xFFD9D9D9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            _isDrawerOpen ? Icons.close_sharp : Icons.menu_open_sharp,
            color: Colors.white,
            size: 30,
          ),
          onPressed: _toggleDrawer,
        ),
        title: Text(
          _selectedIndex == 0 ? ' [ STATUS: ACTIVE ] ' : 
          _selectedIndex == 1 ? ' [ MARKET: OPEN ] ' : ' [ SYSTEM: AUDIT ] ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (isAdmin) _buildAdminBadge(),
          _buildWalletBadge(context),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            color: Colors.black,
            child: Row(
              children: [
                const Text(">>> ", style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                Expanded(
                  child: Text(
                    _selectedIndex == 0 ? "SYNCING_HOME_DATA..." : 
                    _selectedIndex == 1 ? "ACCESS_MARKET_PROTOCOLS..." : "SCANNING_SECURITY_LOGS...",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
                Text("SECURE_FEED", style: TextStyle(color: Colors.grey[600], fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: NoirGlitchWrapper(
                  trigger: _selectedIndex,
                  child: pages[_selectedIndex],
                ),
              ),
              _buildBottomNav(isAdmin),
            ],
          ),
          if (_isDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleDrawer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),
          IgnorePointer(
            ignoring: !_isDrawerOpen, 
            child: _buildAnimatedFloatingDrawer(),
          ),
          if (_showWelcome)
            NoirWelcomeOverlay(
              username: player.name,
              onComplete: () => setState(() => _showWelcome = false),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      onEnd: () {}, // No-op to trigger builder refresh if needed, or use repeating controller
      builder: (context, value, child) {
        // Simple repeating pulse effect
        final opacity = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;
        final currentOpacity = 0.4 + (0.6 * (opacity > 0.5 ? 1.0 - opacity : opacity) * 2);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(currentOpacity * 0.2),
            border: Border.all(color: Colors.red.withOpacity(currentOpacity), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(currentOpacity * 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ],
          ),
          child: const Center(
            child: Text(
              "ADMIN_CLEARANCE",
              style: TextStyle(
                color: Colors.red,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(bool isAdmin) {
    return IgnorePointer(
      ignoring: _isDrawerOpen,
      child: SafeArea(
        top: false,
        child: Container(
          height: 75,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
          ),
          child: Row(
            children: [
              _buildNoirTab(0, Icons.grid_view_sharp, "HOME"),
              const VerticalDivider(width: 4, thickness: 4, color: Colors.black),
              _buildNoirTab(1, Icons.shopping_basket_sharp, "STORE"),
              if (isAdmin) ...[
                const VerticalDivider(width: 4, thickness: 4, color: Colors.black),
                _buildNoirTab(2, Icons.gavel_sharp, "AUDIT"),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFloatingDrawer() {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      alignment: _isDrawerOpen ? const Alignment(-0.8, 0.0) : const Alignment(-3.5, 0.0),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0.0, end: _isDrawerOpen ? 1.0 : 0.0),
        builder: (context, value, child) {
          double flickerOffset = _isDrawerOpen && value < 0.8 ? (value * 20) % 5 : 0;
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(flickerOffset, 0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.82,
                height: MediaQuery.of(context).size.height * 0.65,
                margin: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDrawerOpen ? 1.0 : 0.0),
                      offset: const Offset(10, 10),
                    ),
                  ],
                ),
                child: const DrawerProfileHeader(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_sharp, color: Colors.black, size: 16),
          const SizedBox(width: 4),
          Text(
            context.watch<Player>().wallet_amount.toString(),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNoirTab(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Container(
          color: isSelected ? Colors.black : Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoirGlitchWrapper extends StatefulWidget {
  final Widget child;
  final int trigger;
  const NoirGlitchWrapper({super.key, required this.child, required this.trigger});

  @override
  State<NoirGlitchWrapper> createState() => _NoirGlitchWrapperState();
}

class _NoirGlitchWrapperState extends State<NoirGlitchWrapper> {
  bool _isGlitching = false;
  Timer? _glitchTimer;

  @override
  void didUpdateWidget(NoirGlitchWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _startGlitch();
    }
  }

  void _startGlitch() {
    _glitchTimer?.cancel();
    setState(() => _isGlitching = true);
    _glitchTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isGlitching = false);
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGlitching) return widget.child;
    return Stack(
      children: [
        widget.child,
        Transform.translate(
          offset: const Offset(-5, 2),
          child: Opacity(
            opacity: 0.5,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.cyan, BlendMode.screen),
              child: widget.child,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(5, -2),
          child: Opacity(
            opacity: 0.5,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.red, BlendMode.screen),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}