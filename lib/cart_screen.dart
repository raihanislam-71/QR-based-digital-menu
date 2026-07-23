import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_manu/coupon_offer_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'cart_manager.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  Future<void> _placeOrder(String paymentMethod) async {
    final prefs = await SharedPreferences.getInstance();
    final String? tableNo = prefs.getString('selected_table');

    String deviceUserId = prefs.getString('device_user_id') ?? "";
    if (deviceUserId.isEmpty) {
      var uuid = const Uuid();
      deviceUserId = 'guest_${uuid.v4()}';
      await prefs.setString('device_user_id', deviceUserId);
    }

    // ১. ফায়ারবেসে অর্ডার সেন্ড করা
    await FirebaseFirestore.instance.collection('orders').add({
      'tableNumber': '1',
      'userId': deviceUserId,
      'item': Cart.items
          .map(
            (e) => {
          'name': e.item.name,
          'price': e.item.price,
          'quantity': e.quantity,
        },
      )
          .toList(),
      'totalPrice': calculateTotal(Cart.total),
      'status': 'panding',
      'estimatedTime': '',
      'couponChecked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ ২. কুপন লিমিট ও কাউন্টার আপডেট লজিক (যা আপনার দরকার ছিল)
    if (appliedCoupon != null && appliedCoupon!['id'] != null) {
      String userCouponDocId = appliedCoupon!['id'];

      try {
        // ফায়ারবেস থেকে লাইভ ইউজার কুপন ডকুমেন্টটি আনা
        DocumentSnapshot userCouponSnap = await FirebaseFirestore.instance
            .collection('user_coupons')
            .doc(userCouponDocId)
            .get();

        if (userCouponSnap.exists) {
          Map<String, dynamic> data = userCouponSnap.data() as Map<String, dynamic>;
          int currentUsedCount = data['usedCount'] ?? 0;
          int perUserLimit = data['perUserLimit'] ?? 1;

          int newUsedCount = currentUsedCount + 1;

          if (newUsedCount >= perUserLimit) {
            // লিমিট শেষ হয়ে গেলে স্ট্যাটাস 'used' করে দেওয়া হলো যাতে আর না দেখায়
            await FirebaseFirestore.instance
                .collection('user_coupons')
                .doc(userCouponDocId)
                .update({
              'usedCount': newUsedCount,
              'status': 'used',
            });
            debugPrint("🛑 [COUPON] Limit reached! Status marked as used.");
          } else {
            // লিমিট বাকি থাকলে শুধু কাউন্ট ১ বাড়ানো হলো
            await FirebaseFirestore.instance
                .collection('user_coupons')
                .doc(userCouponDocId)
                .update({
              'usedCount': newUsedCount,
            });
            debugPrint("📉 [COUPON] Used count incremented to: $newUsedCount");
          }
        }
      } catch (e) {
        debugPrint("💥 [COUPON ERROR] Error updating user coupon count: $e");
      }
    }
  }

  //coupon code
  Map<String, dynamic>? appliedCoupon;
  double couponDiscount = 0.0;

  double get cartSubTotal {
    double total = 0.0;
    for(var element in Cart.items){
      total += (element.item.price * element.quantity);
    }
    return total;
  }

  double calculateTotal(double subTotal) {
    if (appliedCoupon != null) {
      double minOrder = (appliedCoupon!['minOrder'] is int)
          ? (appliedCoupon!['minOrder'] as int).toDouble()
          : (appliedCoupon!['minOrder'] ?? 0.0);

      double couponValue = (appliedCoupon!['value'] is int)
          ? (appliedCoupon!['value'] as int).toDouble()
          : (appliedCoupon!['value'] ?? 0.0);

      if (subTotal >= minOrder) {
        if (appliedCoupon!['discountType'].toString().toLowerCase() == 'percentage' ||appliedCoupon!['discountType'].toString() == '%' )  {
          couponDiscount = subTotal * (couponValue / 100);
        } else {
          couponDiscount = couponValue;
        }
      } else {
        couponDiscount = 0.0;
      }
    }else{
      couponDiscount = 0.0;
    }
    double finalTotal = subTotal - couponDiscount;
    return finalTotal < 0 ? 0.0 : finalTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () async {
              // কুপন আইকন প্রেস করে কুপন সিলেক্ট করার লজিক (আইডি ট্র্যাকিং সহ)
              final selectedCoupon = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CouponOfferScreen()),
              );
              if (selectedCoupon != null) {
                setState(() {
                  appliedCoupon = selectedCoupon;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Coupon ${selectedCoupon['code']} Applied")),
                );
              }
            },
            icon: Icon(
              Icons.confirmation_num_outlined,
              color: Colors.black,
              size: 28,
            ),
          ),
        ],
      ),
      body: Cart.items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: Cart.items.length,
              itemBuilder: (context, index) => Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        Cart.items[index].item.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Cart.items[index].item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Tk ${Cart.items[index].item.price}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (Cart.items[index].quantity > 1) {
                                Cart.items[index].quantity--;
                              } else {
                                Cart.items.removeAt(index);
                              }
                            });
                          },
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                        Text(
                          "${Cart.items[index].quantity}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              Cart.items[index].quantity++;
                            });
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Tk ${calculateTotal(cartSubTotal).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Order"),
                          content: const Text(
                            "Are you sure you want to place this order?",
                          ),
                          actions: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final selectedCoupon =
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CouponOfferScreen(),
                                          ),
                                        );
                                        if (selectedCoupon != null) {
                                          setState(() {
                                            appliedCoupon =
                                                selectedCoupon;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Coupon ${selectedCoupon['code']} Applied",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        "Use Coupon",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: 30),

                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        await _placeOrder("Order");
                                        Navigator.pop(context);

                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              "Order Place",
                                            ),
                                            content: const Text(
                                              "Your order has been placed successfully",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Cart.items.clear();
                                                  Navigator.of(
                                                    context,
                                                  ).popUntil(
                                                        (route) =>
                                                    route.isFirst,
                                                  );
                                                },
                                                child: const Text("OK"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Order",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Checkout",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
}
