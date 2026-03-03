import 'package:finaltasktastic/scripts/data_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MarketSection extends StatelessWidget {
  final ShopCategory category;
  final Function(ShopItem) onSelect;

  const MarketSection({
    required this.category,
    required this.onSelect,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(color: Colors.black),
              child: Text(
                category.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(child: Container(height: 2, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: category.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: FullWidthShopCard(item: item, onTap: () => onSelect(item)),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class FullWidthShopCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onTap;

  const FullWidthShopCard({required this.item, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 70,
                color: item.accentColor.withOpacity(0.15),
                child: Center(
                  child: Icon(item.icon, color: Colors.black, size: 28),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 9,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Price/Action Side
              Container(
                width: 80,
                decoration: const BoxDecoration(
                  color: Colors.white, // Optional: keeps it solid
                  border: Border(
                    left: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          '\$${item.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          "SELECT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandedShopCard extends StatefulWidget {
  final ShopItem item;
  final Function(int) onBuy;

  const ExpandedShopCard({required this.item, required this.onBuy, super.key});

  @override
  State<ExpandedShopCard> createState() => _ExpandedShopCardState();
}

class _ExpandedShopCardState extends State<ExpandedShopCard> {
  int _quantity = 1;

  void _setMax() {
    // Ensure the Provider is accessible and the property name matches your Player class
    final player = Provider.of<Player>(context, listen: false);
    final wallet = player.wallet_amount;

    if (wallet >= widget.item.price) {
      setState(() {
        _quantity = (wallet / widget.item.price).floor();
        if (_quantity < 1) _quantity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: double.infinity,
            color: widget.item.accentColor.withOpacity(0.8),
            child: Icon(widget.item.icon, color: Colors.black, size: 32),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  widget.item.name.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.item.description.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Row(
                    children: [
                      _btn(
                        "-",
                        () => setState(
                          () => _quantity = _quantity > 1 ? _quantity - 1 : 1,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "$_quantity",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      _btn("+", () => setState(() => _quantity++)),
                      GestureDetector(
                        onTap: _setMax,
                        child: Container(
                          color: Colors.red[900],
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: const Center(
                            child: Text(
                              "MAX",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => widget.onBuy(_quantity),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        "BUY: \$${widget.item.price * _quantity}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 35,
      color: Colors.grey[300],
      child: Center(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ),
  );
}
