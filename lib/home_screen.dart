import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_manu/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'cart_manager.dart';
import 'cart_screen.dart';
import 'coupon_service.dart';
import 'menu_item_model.dart';
import 'order_tracking_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = "";
  String selectedCategory = "All";
  int _currentBannerIndex = 0;
  String? _scannedTable = '1';

  @override
  void initState(){
    super.initState();
    // _loadTableNumber();  //
    CouponService().startListeningToOrders();
  }

  // Future<void> _loadTableNumber()async{  //
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     _scannedTable = prefs.getString('selected_table');
  //   });
  // }    //

  @override
  Widget build(BuildContext context) {

    //order tracking sheet
    void _showOrderTrackingSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => OrderTrackingSheet(tableNumber: _scannedTable ?? '1'),
      );
    }

    //icon function
    Widget _buildIconBadge(
      IconData icon,
      int count,
      VoidCallback onTap, {
      bool isNotification = false,
    }) {
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: IconButton(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.black, size: 28),
            ),
          ),
          if (count > 0)
            Positioned(
              right: 6,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),

                child: Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // ১. Sliver App Bar
          SliverAppBar(
            expandedHeight: 230,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('banners')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var bannerDocs = snapshot.data!.docs;

                  if (bannerDocs.isEmpty) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Text("No Banners Available")),
                    );
                  }
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Carousel Slide
                      CarouselSlider(
                        options: CarouselOptions(
                          height: double.infinity,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 5),
                          viewportFraction: 1.0,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentBannerIndex = index;
                            });
                          },
                        ),
                        // Get Firebase Banner Images List
                        items: bannerDocs.map((doc) {
                          String url = doc['url'];
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            fadeInDuration: Duration.zero,   // fade animation off
                            fadeOutDuration: Duration.zero,  // fade animation off
                            placeholder: (context, url) => const SizedBox.shrink(), // kisu show korbe na
                            errorWidget: (context, url, error) => const SizedBox.shrink(),
                          );
                        }).toList(),
                      ),
                      //Pagination Dots
                      Positioned(
                        bottom: 15,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: bannerDocs.asMap().entries.map((entry) {
                            int index = entry.key;
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              decoration: BoxDecoration(
                                // shape: BoxShape.circle,
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                  _currentBannerIndex == index ? 0.9 : 0.4,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Search Bar & Cart Icon
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 3),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search for dishes",
                          prefixIcon: Icon(Icons.search),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartScreen(),
                              ),
                            ).then((value) => setState(() {}));
                          },
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.black,
                            size: 30,
                          ),
                        ),
                      ),
                      if (Cart.items.isNotEmpty)
                        Positioned(
                          right: 7,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${Cart.items.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 10,),
                  // Notification
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where(
                          'tableNumber',
                          isEqualTo: _scannedTable ?? "1",
                        )
                        .where('status', isEqualTo: 'panding')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int pandingOrderCount = (snapshot.hasData)
                          ? snapshot.data!.docs.length
                          : 0;

                      return _buildIconBadge(
                        Icons.notifications_active,
                        pandingOrderCount,
                        () {
                          _showOrderTrackingSheet(context);
                        },
                        isNotification: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Category List
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('manu_item')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 60);

                Set<String> categorySet = {"All"};
                for (var doc in snapshot.data!.docs) {
                  categorySet.add(doc['category']);
                }
                List<String> categories = categorySet.toList();

                return SizedBox(
                  height: 60,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 20,
                      top: 10,
                      bottom: 5,
                    ),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () =>
                          setState(() => selectedCategory = categories[index]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selectedCategory == categories[index]
                              ? Colors.orange
                              : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            categories[index],
                            style: TextStyle(
                              color: selectedCategory == categories[index]
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Food List
          StreamBuilder<QuerySnapshot>(
            stream: (selectedCategory == "All")
                ? FirebaseFirestore.instance.collection('manu_item').snapshots()
                : FirebaseFirestore.instance
                      .collection('manu_item')
                      .where('category', isEqualTo: selectedCategory)
                      .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Search filtering
              var items = snapshot.data!.docs.where((doc) {
                return doc['name'].toString().toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );
              }).toList();

              return SliverPadding(
                padding: const EdgeInsets.all(15),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var data = items[index].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ItemDetailScreen(itemData: data),
                          ),
                        ).then((value) {
                          if (value == true) {
                            setState(() {});
                          }
                        });
                      },
                      child: _buildFoodCard(data),
                    );
                  }, childCount: items.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Updated Food Card Builder (Top-Right Corner Discount)
  Widget _buildFoodCard(Map<String, dynamic> data) {
    double mainPrice = double.tryParse(data['price'].toString()) ?? 0.0;
    double discountPercent =
        double.tryParse(data['discount']?.toString() ?? '0') ?? 0.0;
    double finalPrice = mainPrice - (mainPrice * (discountPercent / 100));
    bool hasDiscount = discountPercent > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      // Card-er puro structure-tike Stack-e rakha hoyeche jate corner-e badge deya jay
      child: Stack(
        children: [
          Row(
            children: [
              // Image Section
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'],
                  width: 130,
                  height: 130,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => Container(
                    width: 130,
                    height: 130,
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 130,
                    height: 130,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),

              // Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['description'] ?? "",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount)
                                Text(
                                  "Tk $mainPrice",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                "Tk ${hasDiscount ? finalPrice.toStringAsFixed(0) : mainPrice}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${data['rating'] ?? '4.5'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- Dynamic Discount Badge (Top Right Corner of Card) ---
          if (hasDiscount)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(13),
                  ),
                ),
                child: Text(
                  "${discountPercent.toInt()}% OFF",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
