import 'package:budget/colors.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class IconItem {
  final String id;
  final String name;
  final IconData icon;
  final String category;
  final List<String> tags;

  const IconItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    required this.tags,
  });
}

final List<IconItem> iconPackCatalog = [
  // Finance
  IconItem(id: "finance_wallet", name: "Wallet", icon: Icons.account_balance_wallet_rounded, category: "Finance", tags: ["wallet", "money", "cash", "bank"]),
  IconItem(id: "finance_bank", name: "Bank", icon: Icons.account_balance_rounded, category: "Finance", tags: ["bank", "vault", "institution"]),
  IconItem(id: "finance_card", name: "Credit Card", icon: Icons.credit_card_rounded, category: "Finance", tags: ["credit", "debit", "card", "pay"]),
  IconItem(id: "finance_savings", name: "Savings", icon: Icons.savings_rounded, category: "Finance", tags: ["savings", "piggy", "invest"]),
  IconItem(id: "finance_cash", name: "Cash", icon: Icons.payments_rounded, category: "Finance", tags: ["cash", "notes", "bills"]),
  IconItem(id: "finance_receipt", name: "Receipt", icon: Icons.receipt_long_rounded, category: "Finance", tags: ["receipt", "invoice", "bill"]),
  IconItem(id: "finance_trend", name: "Investment", icon: Icons.trending_up_rounded, category: "Finance", tags: ["stocks", "crypto", "growth", "invest"]),
  IconItem(id: "finance_exchange", name: "Currency Exchange", icon: Icons.currency_exchange_rounded, category: "Finance", tags: ["forex", "exchange", "transfer"]),
  IconItem(id: "finance_chart", name: "Portfolio", icon: Icons.pie_chart_rounded, category: "Finance", tags: ["portfolio", "analytics", "pie"]),
  IconItem(id: "finance_tag", name: "Discount", icon: Icons.local_offer_rounded, category: "Finance", tags: ["offer", "discount", "tag"]),

  // Shopping
  IconItem(id: "shop_cart", name: "Shopping Cart", icon: Icons.shopping_cart_rounded, category: "Shopping", tags: ["cart", "store", "buy"]),
  IconItem(id: "shop_bag", name: "Shopping Bag", icon: Icons.shopping_bag_rounded, category: "Shopping", tags: ["bag", "mall", "clothes"]),
  IconItem(id: "shop_store", name: "Store", icon: Icons.store_rounded, category: "Shopping", tags: ["store", "shop", "market"]),
  IconItem(id: "shop_gift", name: "Gift", icon: Icons.card_giftcard_rounded, category: "Shopping", tags: ["gift", "present", "birthday"]),
  IconItem(id: "shop_qr", name: "Scanner", icon: Icons.qr_code_scanner_rounded, category: "Shopping", tags: ["qr", "scan", "barcode"]),

  // Food & Dining
  IconItem(id: "food_restaurant", name: "Restaurant", icon: Icons.restaurant_rounded, category: "Food", tags: ["food", "dinner", "lunch", "eat"]),
  IconItem(id: "food_cafe", name: "Coffee", icon: Icons.local_cafe_rounded, category: "Food", tags: ["coffee", "tea", "cafe"]),
  IconItem(id: "food_bar", name: "Drinks", icon: Icons.local_bar_rounded, category: "Food", tags: ["bar", "drinks", "alcohol", "wine"]),
  IconItem(id: "food_fastfood", name: "Fast Food", icon: Icons.fastfood_rounded, category: "Food", tags: ["burger", "fastfood", "fries"]),
  IconItem(id: "food_pizza", name: "Pizza", icon: Icons.local_pizza_rounded, category: "Food", tags: ["pizza", "snack"]),
  IconItem(id: "food_bakery", name: "Bakery", icon: Icons.bakery_dining_rounded, category: "Food", tags: ["bread", "bakery", "cake"]),

  // Transportation
  IconItem(id: "trans_car", name: "Car", icon: Icons.directions_car_rounded, category: "Transportation", tags: ["car", "drive", "vehicle"]),
  IconItem(id: "trans_gas", name: "Fuel", icon: Icons.local_gas_station_rounded, category: "Transportation", tags: ["fuel", "gas", "petrol"]),
  IconItem(id: "trans_bus", name: "Public Transit", icon: Icons.directions_bus_rounded, category: "Transportation", tags: ["bus", "transit", "public"]),
  IconItem(id: "trans_flight", name: "Flight", icon: Icons.flight_rounded, category: "Transportation", tags: ["plane", "airport", "fly"]),
  IconItem(id: "trans_bike", name: "Bicycle", icon: Icons.pedal_bike_rounded, category: "Transportation", tags: ["bike", "cycle"]),
  IconItem(id: "trans_train", name: "Train", icon: Icons.train_rounded, category: "Transportation", tags: ["train", "metro", "subway"]),

  // Housing & Utilities
  IconItem(id: "house_home", name: "Home", icon: Icons.home_rounded, category: "Housing", tags: ["home", "house", "rent"]),
  IconItem(id: "house_apartment", name: "Apartment", icon: Icons.apartment_rounded, category: "Housing", tags: ["apartment", "building", "flat"]),
  IconItem(id: "house_power", name: "Electricity", icon: Icons.bolt_rounded, category: "Housing", tags: ["power", "electricity", "energy", "utility"]),
  IconItem(id: "house_water", name: "Water", icon: Icons.water_drop_rounded, category: "Housing", tags: ["water", "utility"]),
  IconItem(id: "house_wifi", name: "Internet", icon: Icons.wifi_rounded, category: "Housing", tags: ["wifi", "broadband", "internet"]),
  IconItem(id: "house_repair", name: "Repairs", icon: Icons.handyman_rounded, category: "Housing", tags: ["repair", "tools", "maintenance"]),

  // Health & Fitness
  IconItem(id: "health_gym", name: "Fitness", icon: Icons.fitness_center_rounded, category: "Health", tags: ["gym", "workout", "fitness"]),
  IconItem(id: "health_hospital", name: "Medical", icon: Icons.local_hospital_rounded, category: "Health", tags: ["doctor", "clinic", "hospital"]),
  IconItem(id: "health_meds", name: "Pharmacy", icon: Icons.medication_rounded, category: "Health", tags: ["medicine", "pharmacy", "drugs"]),
  IconItem(id: "health_spa", name: "Wellness", icon: Icons.spa_rounded, category: "Health", tags: ["spa", "relax", "massage"]),

  // Entertainment & Leisure
  IconItem(id: "fun_movie", name: "Movies", icon: Icons.movie_rounded, category: "Entertainment", tags: ["cinema", "movie", "film"]),
  IconItem(id: "fun_games", name: "Gaming", icon: Icons.sports_esports_rounded, category: "Entertainment", tags: ["games", "play", "console"]),
  IconItem(id: "fun_music", name: "Music", icon: Icons.music_note_rounded, category: "Entertainment", tags: ["music", "concert", "audio"]),
  IconItem(id: "fun_park", name: "Amusement", icon: Icons.park_rounded, category: "Entertainment", tags: ["park", "outdoor", "leisure"]),

  // Education & Work
  IconItem(id: "work_laptop", name: "Tech / Work", icon: Icons.laptop_mac_rounded, category: "Work", tags: ["laptop", "computer", "office"]),
  IconItem(id: "work_briefcase", name: "Career", icon: Icons.business_center_rounded, category: "Work", tags: ["job", "business", "career"]),
  IconItem(id: "edu_school", name: "Education", icon: Icons.school_rounded, category: "Education", tags: ["school", "college", "tuition", "study"]),
  IconItem(id: "edu_book", name: "Books", icon: Icons.menu_book_rounded, category: "Education", tags: ["book", "reading", "learn"]),
];

class IconPackPicker extends StatefulWidget {
  final Function(String iconIdentifier)? onSelectedIcon;
  const IconPackPicker({Key? key, this.onSelectedIcon}) : super(key: key);

  @override
  State<IconPackPicker> createState() => _IconPackPickerState();
}

class _IconPackPickerState extends State<IconPackPicker> {
  String _selectedCategory = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    "All",
    "Finance",
    "Shopping",
    "Food",
    "Transportation",
    "Housing",
    "Health",
    "Entertainment",
    "Work",
    "Education",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String shape = appStateSettings["iconShape"] ?? "rounded";

    final filteredIcons = iconPackCatalog.where((item) {
      if (_selectedCategory != "All" && item.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = item.name.toLowerCase().contains(q);
        final tagMatches = item.tags.any((t) => t.toLowerCase().contains(q));
        if (!nameMatches && !tagMatches) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Shape Picker Row
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: IconShapeSelector(),
        ),
        const SizedBox(height: 8),

        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: "search-icons".tr(),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: _categories.map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Icon Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredIcons.length,
            itemBuilder: (context, index) {
              final item = filteredIcons[index];
              return Tooltip(
                message: item.name,
                child: Tappable(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: _getBorderRadiusForShape(shape, 40),
                  onTap: () {
                    if (widget.onSelectedIcon != null) {
                      widget.onSelectedIcon!(item.id);
                    }
                    popRoute(context);
                  },
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  double _getBorderRadiusForShape(String shape, double size) {
    if (shape == "circle") return size / 2;
    if (shape == "squircle") return size * 0.28;
    if (shape == "sharp") return 3.0;
    return 14.0;
  }
}

class IconShapeSelector extends StatefulWidget {
  const IconShapeSelector({Key? key}) : super(key: key);

  @override
  State<IconShapeSelector> createState() => _IconShapeSelectorState();
}

class _IconShapeSelectorState extends State<IconShapeSelector> {
  final List<Map<String, String>> _shapes = [
    {"id": "rounded", "label": "Rounded"},
    {"id": "circle", "label": "Circle"},
    {"id": "squircle", "label": "Squircle"},
    {"id": "sharp", "label": "Square"},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String currentShape = appStateSettings["iconShape"] ?? "rounded";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFont(
            text: "icon-container-shape".tr(),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _shapes.map((s) {
              final isSel = currentShape == s["id"];
              double radius = 12;
              if (s["id"] == "circle") radius = 24;
              if (s["id"] == "squircle") radius = 8;
              if (s["id"] == "sharp") radius = 2;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    updateSettings("iconShape", s["id"], updateGlobalState: true);
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSel ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(radius),
                        border: isSel
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Icon(
                        Icons.category_rounded,
                        size: 20,
                        color: isSel ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFont(
                      text: s["label"]!,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
