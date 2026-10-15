import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppDataStore();
  await store.loadFromDisk();
  runApp(KDHouseApp(store: store));
}

// ============================================================================
// 1. PERSISTENT DATA STORE (100% ADMIN CONTROL WITHOUT CODE CHANGES)
// ============================================================================
class AppDataStore extends ChangeNotifier {
  // Brand & UI Settings (Admin Editable)
  String appTitle = "KD HOUSE";
  String announcementText = "🔥 FESTIVE OFFER: Flat 15% OFF Teak Wood Sofas & Mortise Locks!";
  bool showAnnouncement = true;
  String whatsappNumber = "919876543210"; // Admin can change directly in UI
  String adminPin = "1234";

  // Active Customer Filters
  String activeSegment = "FURNITURE"; // 'FURNITURE' or 'HARDWARE'
  String selectedCategory = "All";
  String searchQuery = "";
  String selectedMaterial = "All";
  double maxPriceFilter = 100000;

  // Dynamic Categories
  List<String> furnitureCategories = ["All", "Sofas", "Beds", "Dining", "Office"];
  List<String> hardwareCategories = ["All", "Locks & Handles", "Power Tools", "Hinges & Channels", "Sanitary"];

  // Dynamic Banners
  List<Map<String, dynamic>> banners = [
    {
      "id": "b1",
      "segment": "FURNITURE",
      "badge": "BESPOKE COLLECTION",
      "title": "Royal Sheesham 6-Seater Dining",
      "subtitle": "Custom sizes & honey-oak polish available",
    },
    {
      "id": "b2",
      "segment": "HARDWARE",
      "badge": "AUTHORIZED DEALER",
      "title": "Heavy-Duty Architectural Hardware",
      "subtitle": "SS-304 Hinges, Smart Digital Locks & Power Tools",
    },
  ];

  // Dynamic Products
  List<Map<String, dynamic>> products = [
    {
      "id": "p1",
      "segment": "FURNITURE",
      "category": "Sofas",
      "name": "Royal L-Shape Velvet Lounger",
      "sku": "KD-FUR-101",
      "price": 42500.0,
      "stock": 6,
      "material": "Teak Wood",
      "dimensions": "84 x 60 x 32 inches",
      "brand": "KD Bespoke",
      "tag": "Best Seller",
      "allowQuote": true,
      "iconCode": Icons.chair.codePoint,
    },
    {
      "id": "p2",
      "segment": "FURNITURE",
      "category": "Beds",
      "name": "King Size Hydraulic Storage Bed",
      "sku": "KD-FUR-104",
      "price": 36000.0,
      "stock": 4,
      "material": "Sheesham Wood",
      "dimensions": "78 x 72 inches",
      "brand": "KD Bespoke",
      "tag": "New Arrival",
      "allowQuote": true,
      "iconCode": Icons.bed.codePoint,
    },
    {
      "id": "p3",
      "segment": "HARDWARE",
      "category": "Locks & Handles",
      "name": "Antique Brass Mortise Handle Set",
      "sku": "KD-HRD-201",
      "price": 1850.0,
      "stock": 85,
      "material": "Solid Brass",
      "dimensions": "10 inch Plate / 200mm Cylinder",
      "brand": "Godrej",
      "tag": "Best Seller",
      "allowQuote": false,
      "iconCode": Icons.vpn_key.codePoint,
    },
    {
      "id": "p4",
      "segment": "HARDWARE",
      "category": "Power Tools",
      "name": "13mm Heavy Duty Impact Drill Kit",
      "sku": "KD-HRD-209",
      "price": 3499.0,
      "stock": 14,
      "material": "Steel / ABS",
      "dimensions": "650W High Torque",
      "brand": "Bosch",
      "tag": "Heavy Duty",
      "allowQuote": false,
      "iconCode": Icons.handyman.codePoint,
    },
  ];

  // Shopping Cart & Orders
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> orders = [
    {
      "id": "ORD-1041",
      "customerName": "Rajesh Kumar",
      "customerPhone": "+91 98000 11223",
      "address": "Station Road, Bhagalpur",
      "total": 44350.0,
      "status": "Shipped",
      "date": "Today, 11:30 AM",
      "itemsSummary": "1x Royal L-Shape Lounger, 1x Brass Mortise Set"
    }
  ];

  // User Auth State
  bool isLoggedIn = true;
  String currentUserName = "Guest Customer";
  String currentUserPhone = "+91 99887 76655";

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('kd_store_v1')) {
      final data = jsonDecode(prefs.getString('kd_store_v1')!);
      appTitle = data['appTitle'] ?? appTitle;
      announcementText = data['announcementText'] ?? announcementText;
      showAnnouncement = data['showAnnouncement'] ?? showAnnouncement;
      whatsappNumber = data['whatsappNumber'] ?? whatsappNumber;
      furnitureCategories = List<String>.from(data['furnitureCategories'] ?? furnitureCategories);
      hardwareCategories = List<String>.from(data['hardwareCategories'] ?? hardwareCategories);
      banners = List<Map<String, dynamic>>.from(data['banners'] ?? banners);
      products = List<Map<String, dynamic>>.from(data['products'] ?? products);
      orders = List<Map<String, dynamic>>.from(data['orders'] ?? orders);
    }
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'appTitle': appTitle,
      'announcementText': announcementText,
      'showAnnouncement': showAnnouncement,
      'whatsappNumber': whatsappNumber,
      'furnitureCategories': furnitureCategories,
      'hardwareCategories': hardwareCategories,
      'banners': banners,
      'products': products,
      'orders': orders,
    });
    await prefs.setString('kd_store_v1', data);
    notifyListeners();
  }

  // Segment & Filter Actions
  void setSegment(String segment) {
    activeSegment = segment;
    selectedCategory = "All";
    selectedMaterial = "All";
    notifyListeners();
  }

  void setCategory(String cat) {
    selectedCategory = cat;
    notifyListeners();
  }

  void setSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  // Cart Actions
  void addToCart(Map<String, dynamic> product) {
    final index = cart.indexWhere((item) => item['id'] == product['id']);
    if (index >= 0) {
      cart[index]['qty'] = (cart[index]['qty'] as int) + 1;
    } else {
      cart.add({...product, 'qty': 1});
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    cart.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  double get cartTotal =>
      cart.fold(0, (sum, item) => sum + ((item['price'] as num) * (item['qty'] as int)));

  void placeOrder(String name, String phone, String address) {
    if (cart.isEmpty) return;
    final summary = cart.map((e) => "${e['qty']}x ${e['name']}").join(", ");
    orders.insert(0, {
      "id": "ORD-${1042 + orders.length}",
      "customerName": name,
      "customerPhone": phone,
      "address": address,
      "total": cartTotal,
      "status": "Pending",
      "date": "Just now",
      "itemsSummary": summary,
    });
    cart.clear();
    saveToDisk();
  }

  // Admin Control Actions
  void updateUiSettings({
    required String newTitle,
    required String newAnnouncement,
    required bool visible,
    required String newWhatsapp,
  }) {
    appTitle = newTitle;
    announcementText = newAnnouncement;
    showAnnouncement = visible;
    whatsappNumber = newWhatsapp;
    saveToDisk();
  }

  void upsertProduct(Map<String, dynamic> product) {
    final index = products.indexWhere((p) => p['id'] == product['id']);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }
    saveToDisk();
  }

  void deleteProduct(String id) {
    products.removeWhere((p) => p['id'] == id);
    saveToDisk();
  }

  void addCategory(String segment, String categoryName) {
    if (categoryName.trim().isEmpty) return;
    if (segment == "FURNITURE" && !furnitureCategories.contains(categoryName)) {
      furnitureCategories.add(categoryName.trim());
    } else if (segment == "HARDWARE" && !hardwareCategories.contains(categoryName)) {
      hardwareCategories.add(categoryName.trim());
    }
    saveToDisk();
  }

  void removeCategory(String segment, String categoryName) {
    if (categoryName == "All") return;
    if (segment == "FURNITURE") {
      furnitureCategories.remove(categoryName);
    } else {
      hardwareCategories.remove(categoryName);
    }
    saveToDisk();
  }

  void updateBanner(String segment, String badge, String title, String subtitle) {
    final idx = banners.indexWhere((b) => b['segment'] == segment);
    if (idx >= 0) {
      banners[idx] = {
        "id": banners[idx]['id'],
        "segment": segment,
        "badge": badge,
        "title": title,
        "subtitle": subtitle,
      };
    }
    saveToDisk();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final idx = orders.indexWhere((o) => o['id'] == orderId);
    if (idx >= 0) {
      orders[idx]['status'] = newStatus;
      saveToDisk();
    }
  }
}

// ============================================================================
// 2. THEME & MAIN ENTRY WIDGET (CHARCOAL #1A1D20 & WARM AMBER/GOLD #D4AF37)
// ============================================================================
const Color kCharcoal = Color(0xFF1A1D20);
const Color kDarkSurface = Color(0xFF25292E);
const Color kAmberGold = Color(0xFFD4AF37);
const Color kWarmOrange = Color(0xFFF59E0B);
const Color kAlabaster = Color(0xFFF8F9FA);

class KDHouseApp extends StatelessWidget {
  final AppDataStore store;
  const KDHouseApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          title: 'KD Hardware & Furniture House',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: kAlabaster,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kAmberGold,
              primary: kCharcoal,
              secondary: kAmberGold,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: kCharcoal,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          home: MainShell(store: store),
        );
      },
    );
  }
}

// ============================================================================
// 3. CUSTOM MINIMALIST "KD" LOGO PAINTER (HAMMER + CHAIR OUTLINE)
// ============================================================================
class KDLogoBadge extends StatelessWidget {
  final double size;
  const KDLogoBadge({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kDarkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kAmberGold, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 5,
            top: 6,
            child: Icon(Icons.hardware, color: kAmberGold, size: size * 0.48),
          ),
          Positioned(
            right: 4,
            bottom: 5,
            child: Icon(Icons.chair_alt, color: Colors.white, size: size * 0.48),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. CUSTOMER SHELL & NAVIGATION
// ============================================================================
class MainShell extends StatefulWidget {
  final AppDataStore store;
  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _promptAdminLogin() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCharcoal,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: kAmberGold),
            SizedBox(width: 8),
            Text("Admin Control Center", style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Admin PIN (Default: 1234) to modify products, banners, categories, and orders.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter 1234",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: kDarkSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kAmberGold, foregroundColor: kCharcoal),
            onPressed: () {
              if (pinCtrl.text.trim() == widget.store.adminPin) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminDashboardScreen(store: widget.store)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid PIN! Default PIN is 1234.")),
                );
              }
            },
            child: const Text("Unlock Admin", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CustomerHomeScreen(store: widget.store),
      CartScreen(store: widget.store),
      OrdersAndProfileScreen(store: widget.store),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const KDLogoBadge(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.store.appTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "HARDWARE & FURNITURE HOUSE",
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 2.0,
                      color: kAmberGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Admin Quick Access Button
          TextButton.icon(
            onPressed: _promptAdminLogin,
            icon: const Icon(Icons.tune, color: kAmberGold, size: 18),
            label: const Text(
              "Admin",
              style: TextStyle(color: kAmberGold, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: kAmberGold.withOpacity(0.25),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: kCharcoal),
            label: 'Showroom',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: widget.store.cart.isNotEmpty,
              label: Text('${widget.store.cart.length}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_bag, color: kCharcoal),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: kCharcoal),
            label: 'Orders & Auth',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. CUSTOMER HOME & CATALOG SCREEN (SEGMENT SWITCHER + WHATSAPP QUOTE)
// ============================================================================
class CustomerHomeScreen extends StatelessWidget {
  final AppDataStore store;
  const CustomerHomeScreen({super.key, required this.store});

  Future<void> _launchWhatsAppQuote(BuildContext context, Map<String, dynamic> product) async {
    final text = Uri.encodeComponent(
      "Hello ${store.appTitle}! 👋\n\n"
      "I want to inquire / get a custom quote for:\n"
      "• *Item:* ${product['name']}\n"
      "• *SKU:* ${product['sku']}\n"
      "• *Listed Price:* ₹${product['price']}\n"
      "• *Standard Dimensions:* ${product['dimensions']}\n\n"
      "Please share customization details and delivery timeline.",
    );
    final url = Uri.parse("https://wa.me/${store.whatsappNumber}?text=$text");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("WhatsApp inquiry ready for +${store.whatsappNumber}")),
        );
      }
    }
  }

  void _openFilterSheet(BuildContext context) {
    final allMaterials = <String>{
      "All",
      ...store.products
          .where((p) => p['segment'] == store.activeSegment)
          .map((p) => p['material'].toString())
    }.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Filter Catalog by Material & Price",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  const Text("Select Material / Finish:", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: allMaterials.map((mat) {
                      final selected = store.selectedMaterial == mat;
                      return ChoiceChip(
                        label: Text(mat),
                        selected: selected,
                        selectedColor: kAmberGold,
                        onSelected: (_) {
                          store.selectedMaterial = mat;
                          store.notifyListeners();
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Max Price: ₹${store.maxPriceFilter.toInt()}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: store.maxPriceFilter,
                    min: 500,
                    max: 100000,
                    divisions: 100,
                    activeColor: kCharcoal,
                    onChanged: (val) {
                      store.maxPriceFilter = val;
                      store.notifyListeners();
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCharcoal,
                        foregroundColor: kAmberGold,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Apply Filters"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFurniture = store.activeSegment == "FURNITURE";
    final categories = isFurniture ? store.furnitureCategories : store.hardwareCategories;
    final currentBanner = store.banners.firstWhere(
      (b) => b['segment'] == store.activeSegment,
      orElse: () => store.banners.first,
    );

    final filteredProducts = store.products.where((p) {
      if (p['segment'] != store.activeSegment) return false;
      if (store.selectedCategory != "All" && p['category'] != store.selectedCategory) return false;
      if (store.selectedMaterial != "All" && p['material'] != store.selectedMaterial) return false;
      if ((p['price'] as num) > store.maxPriceFilter) return false;
      if (store.searchQuery.isNotEmpty) {
        final q = store.searchQuery.toLowerCase();
        return p['name'].toString().toLowerCase().contains(q) ||
            p['brand'].toString().toLowerCase().contains(q) ||
            p['material'].toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // 1. Dynamic Announcement Bar
        if (store.showAnnouncement)
          Container(
            width: double.infinity,
            color: kAmberGold,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              store.announcementText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kCharcoal,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // 2. Dual Segment Switcher (Furniture vs Hardware)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => store.setSegment("FURNITURE"),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isFurniture ? kCharcoal : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.weekend,
                                size: 17,
                                color: isFurniture ? kAmberGold : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "FURNITURE",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: isFurniture ? kAmberGold : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => store.setSegment("HARDWARE"),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isFurniture ? kCharcoal : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.construction,
                                size: 17,
                                color: !isFurniture ? kAmberGold : Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "HARDWARE",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: !isFurniture ? kAmberGold : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Search & Advanced Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: store.setSearch,
                      decoration: InputDecoration(
                        hintText: isFurniture
                            ? "Search sofas, beds, teak wood..."
                            : "Search locks, drills, hinges, Bosch...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openFilterSheet(context),
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: kCharcoal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.filter_list, color: kAmberGold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Admin-Controlled Promotional Hero Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kCharcoal, kDarkSurface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAmberGold.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kAmberGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentBanner['badge'].toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: kCharcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentBanner['title'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentBanner['subtitle'].toString(),
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Dynamic Category Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = categories[i];
                    final isSelected = store.selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: kCharcoal,
                      labelStyle: TextStyle(
                        color: isSelected ? kAmberGold : kCharcoal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => store.setCategory(cat),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 6. Product Cards Grid
              if (filteredProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text("No matching products found. Adjust filters or add items in Admin."),
                  ),
                )
              else
                ...filteredProducts.map((product) {
                  final inStock = (product['stock'] as int) > 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0.8,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Visual Box
                              Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: kCharcoal.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  IconData(
                                    (product['iconCode'] as int?) ?? Icons.inventory_2.codePoint,
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  size: 40,
                                  color: kCharcoal,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: kCharcoal,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            product['tag'].toString().toUpperCase(),
                                            style: const TextStyle(
                                              color: kAmberGold,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          inStock ? "In Stock (${product['stock']})" : "Out of Stock",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: inStock ? Colors.green.shade700 : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      product['name'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: kCharcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "${product['material']} • ${product['dimensions']} • ${product['brand']}",
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "₹${(product['price'] as num).toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: kCharcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kCharcoal,
                                    foregroundColor: kAmberGold,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: inStock
                                      ? () {
                                          store.addToCart(product);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("${product['name']} added to cart!"),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                                  label: const Text(
                                    "ADD TO CART",
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              if (product['allowQuote'] == true) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.green.shade800,
                                      side: BorderSide(color: Colors.green.shade600),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _launchWhatsAppQuote(context, product),
                                    icon: const Icon(Icons.chat, size: 16),
                                    label: const Text(
                                      "WHATSAPP QUOTE",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 6. SHOPPING CART & CHECKOUT SCREEN
// ============================================================================
class CartScreen extends StatelessWidget {
  final AppDataStore store;
  const CartScreen({super.key, required this.store});

  void _showCheckoutDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: store.currentUserName);
    final phoneCtrl = TextEditingController(text: store.currentUserPhone);
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delivery Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Mobile Number"),
            ),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: "Complete Delivery Address"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kCharcoal, foregroundColor: kAmberGold),
            onPressed: () {
              store.placeOrder(
                nameCtrl.text.isEmpty ? "Customer" : nameCtrl.text,
                phoneCtrl.text.isEmpty ? "+91 9000000000" : phoneCtrl.text,
                addrCtrl.text.isEmpty ? "Store Pickup / Local Delivery" : addrCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Order placed! Track status in the Orders tab.")),
              );
            },
            child: const Text("Place Order"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (store.cart.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text("Your cart is empty", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Browse Hardware or Furniture to add items."),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: store.cart.length,
            itemBuilder: (ctx, i) {
              final item = store.cart[i];
              return Card(
                child: ListTile(
                  title: Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("₹${item['price']} x ${item['qty']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => store.removeFromCart(item['id'].toString()),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Payable", style: TextStyle(color: Colors.grey)),
                  Text(
                    "₹${store.cartTotal.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCharcoal,
                  foregroundColor: kAmberGold,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _showCheckoutDialog(context),
                child: const Text("PROCEED TO CHECKOUT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 7. CUSTOMER ORDERS & OTP / PROFILE SCREEN
// ============================================================================
class OrdersAndProfileScreen extends StatelessWidget {
  final AppDataStore store;
  const OrdersAndProfileScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          color: kCharcoal,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: kAmberGold,
              child: Icon(Icons.person, color: kCharcoal),
            ),
            title: Text(
              store.currentUserName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${store.currentUserPhone} • Verified via OTP",
              style: const TextStyle(color: kAmberGold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Live Order Tracking History",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...store.orders.map((ord) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ord['id'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      Chip(
                        label: Text(
                          ord['status'].toString().toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: kAmberGold.withOpacity(0.25),
                      ),
                    ],
                  ),
                  Text(ord['itemsSummary'].toString()),
                  const SizedBox(height: 4),
                  Text(
                    "Total: ₹${ord['total']} • ${ord['date']}",
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// 8. DEDICATED ADMIN PANEL (100% ZERO-CODE CONTROL OVER ALL APP ELEMENTS)
// ============================================================================
class AdminDashboardScreen extends StatefulWidget {
  final AppDataStore store;
  const AdminDashboardScreen({super.key, required this.store});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _openProductEditor({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    String segment = existing?['segment'] ?? "FURNITURE";
    final nameCtrl = TextEditingController(text: existing?['name'] ?? "");
    final skuCtrl = TextEditingController(
      text: existing?['sku'] ?? "KD-${DateTime.now().millisecondsSinceEpoch % 1000}",
    );
    final priceCtrl = TextEditingController(text: existing?['price']?.toString() ?? "");
    final stockCtrl = TextEditingController(text: existing?['stock']?.toString() ?? "10");
    final matCtrl = TextEditingController(text: existing?['material'] ?? "Teak Wood");
    final dimCtrl = TextEditingController(text: existing?['dimensions'] ?? "Standard");
    final brandCtrl = TextEditingController(text: existing?['brand'] ?? "KD House");
    final tagCtrl = TextEditingController(text: existing?['tag'] ?? "New Arrival");
    final catCtrl = TextEditingController(text: existing?['category'] ?? "Sofas");
    bool allowQuote = existing?['allowQuote'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Edit Product" : "Add New Product"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: segment,
                  decoration: const InputDecoration(labelText: "Business Segment"),
                  items: const [
                    DropdownMenuItem(value: "FURNITURE", child: Text("FURNITURE")),
                    DropdownMenuItem(value: "HARDWARE", child: Text("HARDWARE")),
                  ],
                  onChanged: (v) => setDialogState(() => segment = v!),
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Product Name")),
                TextField(controller: catCtrl, decoration: const InputDecoration(labelText: "Category Name")),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price (₹)"),
                ),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Stock Quantity"),
                ),
                TextField(controller: matCtrl, decoration: const InputDecoration(labelText: "Material / Finish")),
                TextField(controller: dimCtrl, decoration: const InputDecoration(labelText: "Size / Dimensions")),
                TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: "Brand")),
                TextField(
                  controller: tagCtrl,
                  decoration: const InputDecoration(labelText: "Badge Tag (e.g. Best Seller, New Arrival)"),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Enable WhatsApp Custom Quote"),
                  value: allowQuote,
                  onChanged: (v) => setDialogState(() => allowQuote = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kCharcoal, foregroundColor: kAmberGold),
              onPressed: () {
                widget.store.addCategory(segment, catCtrl.text.trim());
                widget.store.upsertProduct({
                  "id": existing?['id'] ?? "p_${DateTime.now().millisecondsSinceEpoch}",
                  "segment": segment,
                  "category": catCtrl.text.trim(),
                  "name": nameCtrl.text.trim(),
                  "sku": skuCtrl.text.trim(),
                  "price": double.tryParse(priceCtrl.text) ?? 999.0,
                  "stock": int.tryParse(stockCtrl.text) ?? 1,
                  "material": matCtrl.text.trim(),
                  "dimensions": dimCtrl.text.trim(),
                  "brand": brandCtrl.text.trim(),
                  "tag": tagCtrl.text.trim(),
                  "allowQuote": allowQuote,
                  "iconCode": segment == "FURNITURE" ? Icons.chair.codePoint : Icons.build.codePoint,
                });
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text("Save Live"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kCharcoal,
        title: const Text("100% Admin Control Panel", style: TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: kAmberGold,
          labelColor: kAmberGold,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: "Products"),
            Tab(icon: Icon(Icons.category), text: "Categories"),
            Tab(icon: Icon(Icons.web), text: "Banners & UI"),
            Tab(icon: Icon(Icons.local_shipping), text: "Orders"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAmberGold,
        foregroundColor: kCharcoal,
        onPressed: () => _openProductEditor(),
        icon: const Icon(Icons.add),
        label: const Text("Add Product", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: PRODUCT MANAGEMENT
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: store.products.length,
            itemBuilder: (ctx, i) {
              final p = store.products[i];
              return Card(
                child: ListTile(
                  title: Text("${p['name']} (${p['segment']})"),
                  subtitle: Text("₹${p['price']} • Stock: ${p['stock']} • Tag: ${p['tag']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openProductEditor(existing: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          store.deleteProduct(p['id'].toString());
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // TAB 2: DYNAMIC CATEGORIES (INDEPENDENT FOR HARDWARE & FURNITURE)
           _CategoryManagerTab(store: store, onChanged: () => setState(() {})),

          // TAB 3: BANNER & UI CONTROL
          _BannerAndUiTab(store: store, onChanged: () => setState(() {})),

          // TAB 4: ORDER MANAGEMENT
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: store.orders.length,
            itemBuilder: (ctx, i) {
              final ord = store.orders[i];
              return Card(
                child: ListTile(
                  title: Text("${ord['id']} — ${ord['customerName']} (₹${ord['total']})"),
                  subtitle: Text("${ord['itemsSummary']}\n${ord['address']} • ${ord['customerPhone']}"),
                  isThreeLine: true,
                  trailing: DropdownButton<String>(
                    value: ord['status'].toString(),
                    items: ["Pending", "Shipped", "Delivered", "Cancelled"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        store.updateOrderStatus(ord['id'].toString(), val);
                        setState(() {});
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryManagerTab extends StatefulWidget {
  final AppDataStore store;
  final VoidCallback onChanged;
  const _CategoryManagerTab({required this.store, required this.onChanged});

  @override
  State<_CategoryManagerTab> createState() => _CategoryManagerTabState();
}

class _CategoryManagerTabState extends State<_CategoryManagerTab> {
  final _furCatCtrl = TextEditingController();
  final _hrdCatCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Furniture Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Wrap(
          spacing: 8,
          children: widget.store.furnitureCategories.map((c) {
            return Chip(
              label: Text(c),
              onDeleted: c == "All"
                  ? null
                  : () {
                      widget.store.removeCategory("FURNITURE", c);
                      widget.onChanged();
                    },
            );
          }).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _furCatCtrl,
                decoration: const InputDecoration(hintText: "New Furniture Category"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.store.addCategory("FURNITURE", _furCatCtrl.text);
                _furCatCtrl.clear();
                widget.onChanged();
              },
              child: const Text("Add"),
            ),
          ],
        ),
        const Divider(height: 36),
        const Text("Hardware Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Wrap(
          spacing: 8,
          children: widget.store.hardwareCategories.map((c) {
            return Chip(
              label: Text(c),
              onDeleted: c == "All"
                  ? null
                  : () {
                      widget.store.removeCategory("HARDWARE", c);
                      widget.onChanged();
                    },
            );
          }).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hrdCatCtrl,
                decoration: const InputDecoration(hintText: "New Hardware Category"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.store.addCategory("HARDWARE", _hrdCatCtrl.text);
                _hrdCatCtrl.clear();
                widget.onChanged();
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ],
    );
  }
}

class _BannerAndUiTab extends StatefulWidget {
  final AppDataStore store;
  final VoidCallback onChanged;
  const _BannerAndUiTab({required this.store, required this.onChanged});

  @override
  State<_BannerAndUiTab> createState() => _BannerAndUiTabState();
}

class _BannerAndUiTabState extends State<_BannerAndUiTab> {
  late TextEditingController _titleCtrl;
  late TextEditingController _annCtrl;
  late TextEditingController _waCtrl;
  late TextEditingController _furBannerTitleCtrl;
  late TextEditingController _hrdBannerTitleCtrl;
  bool _showAnn = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.store.appTitle);
    _annCtrl = TextEditingController(text: widget.store.announcementText);
    _waCtrl = TextEditingController(text: widget.store.whatsappNumber);
    _showAnn = widget.store.showAnnouncement;
    _furBannerTitleCtrl = TextEditingController(text: widget.store.banners[0]['title'].toString());
    _hrdBannerTitleCtrl = TextEditingController(text: widget.store.banners[1]['title'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Global App Branding & WhatsApp Control", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "App Header Title")),
        TextField(
          controller: _waCtrl,
          decoration: const InputDecoration(labelText: "WhatsApp Business Number (with country code)"),
        ),
        TextField(controller: _annCtrl, decoration: const InputDecoration(labelText: "Top Announcement Ticker")),
        SwitchListTile(
          title: const Text("Show Top Announcement Bar"),
          value: _showAnn,
          onChanged: (v) => setState(() => _showAnn = v),
        ),
        const Divider(),
        const Text("Hero Promotional Banners", style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: _furBannerTitleCtrl,
          decoration: const InputDecoration(labelText: "Furniture Hero Banner Headline"),
        ),
        TextField(
          controller: _hrdBannerTitleCtrl,
          decoration: const InputDecoration(labelText: "Hardware Hero Banner Headline"),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: kCharcoal, foregroundColor: kAmberGold),
          onPressed: () {
            widget.store.updateUiSettings(
              newTitle: _titleCtrl.text.trim(),
              newAnnouncement: _annCtrl.text.trim(),
              visible: _showAnn,
              newWhatsapp: _waCtrl.text.trim(),
            );
            widget.store.updateBanner(
              "FURNITURE",
              "BESPOKE COLLECTION",
              _furBannerTitleCtrl.text.trim(),
              "Custom sizes & honey-oak polish available",
            );
            widget.store.updateBanner(
              "HARDWARE",
              "AUTHORIZED DEALER",
              _hrdBannerTitleCtrl.text.trim(),
              "SS-304 Hinges, Smart Digital Locks & Power Tools",
            );
            widget.onChanged();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("UI & Banner Settings Published Live!")),
            );
          },
          icon: const Icon(Icons.publish),
          label: const Text("PUBLISH CHANGES LIVE"),
        ),
      ],
    );
  }
}