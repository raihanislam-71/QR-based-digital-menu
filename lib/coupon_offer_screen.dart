/*
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CouponOfferScreen extends StatefulWidget {
  const CouponOfferScreen({super.key});

  @override
  State<CouponOfferScreen> createState() => _CouponOfferScreenState();
}

class _CouponOfferScreenState extends State<CouponOfferScreen> {
  // === NEW: ডিভাইস আইডি স্টেট ভেরিয়েবল এবং মেথড ===
  String _currentUserId = "";
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceUserId();
  }

  // লোডাল মেমোরি থেকে ডিভাইস আইডি রিড করার ফাংশন
  Future<void> _loadDeviceUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // OrderTrackingSheet যে কি ('device_user_id') ব্যবহার করেছে, সেটাই এখানে রিড হবে
      _currentUserId = prefs.getString('device_user_id') ?? "default_guest";
      _isLoadingUser = false;
    });
  }

  bool isCouponLiveAndActive(dynamic startData,
      dynamic endData,
      bool adminStatus,) {
    if (adminStatus == false) return false;
    // রিওয়ার্ড কুপনে অনেক সময় startDate নাও থাকতে পারে, তাই সেফটি হ্যান্ডলার
    if (endData == null) return true;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    DateTime end = (endData as Timestamp).toDate();
    DateTime endDate = DateTime(end.year, end.month, end.day);

    if (startData != null) {
      DateTime start = (startData as Timestamp).toDate();
      DateTime startDate = DateTime(start.year, start.month, start.day);
      if (today.isBefore(startDate)) return false;
    }

    if (today.isAfter(endDate)) {
      return false;
    }
    return true;
  }

  String getRemainingDay(dynamic endDateData) {
    if (endDateData == null) return "NO LIMIT";

    try {
      DateTime expiry = (endDateData as Timestamp).toDate();
      DateTime now = DateTime.now();

      DateTime expiryOnlyDate = DateTime(expiry.year, expiry.month, expiry.day);
      DateTime nowOnlyDate = DateTime(now.year, now.month, now.day);
      Duration difference = expiryOnlyDate.difference(nowOnlyDate);

      if (difference.isNegative) {
        return "EXPIRED";
      } else if (difference.inDays == 0) {
        return "EXPIRES TODAY";
      } else if (difference.inDays == 1) {
        return "1 DAY LEFT";
      } else {
        return "${difference.inDays} DAYS LEFT";
      }
    } catch (e) {
      return "N/A";
    }
  }

  void markCouponsAsRead(List<QueryDocumentSnapshot> docs, String currentUserId) {
    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List viewedUsers = data['viewedBy'] ?? []; // === CHANGED: স্পেলিং ফিক্সড 'viewedBy' ===
      if (!viewedUsers.contains(currentUserId)) {
        doc.reference.update({
          'viewedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ডিভাইস আইডি লোড হতে থাকলে সার্কুলার ইন্ডিকেটর দেখাবে
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Coupon Offer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade50,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,

      // === CHANGED: এখন কুয়েরি হবে user_coupons কালেকশনে এবং নির্দিষ্ট ডিভাইস আইডির জন্য ===
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_coupons')
            .where('userId', isEqualTo: _currentUserId)
            .where('status', isEqualTo: 'available') // শুধু যেগুলো এখনো ব্যবহার করেনি
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No coupons available.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var activeDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return isCouponLiveAndActive(
              data['startDate'], // এটি নাল হলেও সমস্যা নেই
              data['endDate'],
              true, // অলরেডি ইউজার কুপন পাওয়ায় স্ট্যাটাস ট্রু ধরাই যায়
            );
          }).toList();

          if (activeDocs.isEmpty) {
            return const Center(
              child: Text(
                "No active coupon found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            markCouponsAsRead(activeDocs, _currentUserId);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            itemCount: activeDocs.length,
            itemBuilder: (context, index) {
              var doc = activeDocs[index];
              Map<String, dynamic> coupon = doc.data() as Map<String, dynamic>;
              String docId = doc.id;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          coupon['code'] ?? "CODE", // === CHANGED: কালেকশন অনুযায়ী ফিল্ড কি 'code' ===
                          style: const TextStyle(
                            color: Color(0xFF8C9EFF),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'docId': docId,
                              'code': coupon['code'],
                              'discountType': coupon['discountType'],
                              'value': coupon['value'], // === CHANGED: ফিল্ড কি 'value' ===
                              'minOrder': coupon['minOrder'] ?? 0,
                            });
                          },
                          child: const Text(
                            "USE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6,),
                    Text(
                      coupon['discountType'] == "Amount" || coupon['discountType'] == "Amount (Tk)"
                          ? "${coupon['value']} Tk Discount"
                          : "${coupon['value']}% OFF",
                      style: const TextStyle(color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 15,),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _customChip(
                          coupon['couponType'] ?? "Reward",
                          const Color(0xFFE8EAF6),
                          const Color(0xFF3F51B5),
                        ),
                        _customChip(
                          "ACTIVE",
                          const Color(0xFFE8F5E9),
                          const Color(0xFF2E7D32),
                        ),
                        // === CHANGED: ইউজার কালেকশনে লিমিট ১ ট্র্যাকিং করাই থাকে তাই ডাটাবেজ সেফ ভ্যালু ===
                        _customChip(
                          "LIMIT : ${coupon['perUserLimit']}",
                          const Color(0xFFFFF3E0),
                          const Color(0xFFE65100),
                        ),
                        _customChip(
                          getRemainingDay(coupon['endDate']),
                          const Color(0xFFFFEBEE),
                          const Color(0xFFB71C1C),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _customChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: textColor, fontSize: 10,fontWeight: FontWeight.bold,letterSpacing: 0.5),
      ),
    );
  }
}

*/

/*
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CouponOfferScreen extends StatefulWidget {
  const CouponOfferScreen({super.key});

  @override
  State<CouponOfferScreen> createState() => _CouponOfferScreenState();
}

class _CouponOfferScreenState extends State<CouponOfferScreen> {
  String _currentUserId = "";
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceUserId();
  }

  Future<void> _loadDeviceUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('device_user_id') ?? "default_guest";
      _isLoadingUser = false;
    });
  }

  bool isCouponLiveAndActive(dynamic startData, dynamic endData, bool adminStatus) {
    if (adminStatus == false) return false;
    if (endData == null) return true;

    try {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      DateTime end = (endData as Timestamp).toDate();
      DateTime endDate = DateTime(end.year, end.month, end.day);

      if (startData != null) {
        DateTime start = (startData as Timestamp).toDate();
        DateTime startDate = DateTime(start.year, start.month, start.day);
        if (today.isBefore(startDate)) return false;
      }

      // কুপনটি যেন শেষ দিনের রাত ১২টা পর্যন্ত কাজ করে (add 1 day সেফটি)
      if (today.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Coupon date parsing error: $e");
      return false; // ডেট ফরম্যাটে ভুল থাকলে অ্যাপ ক্র্যাশ না করে কুপনটি হাইড রাখবে
    }
  }

  String getRemainingDay(dynamic endDateData) {
    if (endDateData == null) return "NO LIMIT";

    try {
      DateTime expiry = (endDateData as Timestamp).toDate();
      DateTime now = DateTime.now();

      DateTime expiryOnlyDate = DateTime(expiry.year, expiry.month, expiry.day);
      DateTime nowOnlyDate = DateTime(now.year, now.month, now.day);
      Duration difference = expiryOnlyDate.difference(nowOnlyDate);

      if (difference.isNegative) {
        return "EXPIRED";
      } else if (difference.inDays == 0) {
        return "EXPIRES TODAY";
      } else if (difference.inDays == 1) {
        return "1 DAY LEFT";
      } else {
        return "${difference.inDays} DAYS LEFT";
      }
    } catch (e) {
      return "N/A";
    }
  }

  void markCouponsAsRead(List<QueryDocumentSnapshot> docs, String currentUserId) {
    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List viewedUsers = data['viewedBy'] ?? [];
      if (!viewedUsers.contains(currentUserId)) {
        doc.reference.update({
          'viewedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Coupon Offer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade50,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_coupons')
            .where('userId', isEqualTo: _currentUserId)
            .where('status', isEqualTo: 'available')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No coupons available.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var activeDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return isCouponLiveAndActive(
              data['startDate'],
              data['endDate'],
              true,
            );
          }).toList();

          if (activeDocs.isEmpty) {
            return const Center(
              child: Text(
                "No active coupon found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            markCouponsAsRead(activeDocs, _currentUserId);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            itemCount: activeDocs.length,
            itemBuilder: (context, index) {
              var doc = activeDocs[index];
              Map<String, dynamic> coupon = doc.data() as Map<String, dynamic>;
              String docId = doc.id;

              // ✅ ফিক্স ১: value কে int/double উভয় ফরম্যাট থেকেই নিরাপদে double-এ রূপান্তর
              double couponValue = 0.0;
              if (coupon['value'] != null) {
                couponValue = (coupon['value'] is int)
                    ? (coupon['value'] as int).toDouble()
                    : (coupon['value'] as double);
              }

              // ✅ ফিক্স ২: minOrder কে নিরাপদে double-এ রূপান্তর (ক্র্যাশ প্রোটেকশন)
              double minOrderValue = 0.0;
              if (coupon['minOrder'] != null) {
                minOrderValue = (coupon['minOrder'] is int)
                    ? (coupon['minOrder'] as int).toDouble()
                    : (coupon['minOrder'] as double);
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          coupon['code'] ?? "CODE",
                          style: const TextStyle(
                            color: Color(0xFF8C9EFF),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        // ✅ ফিক্স ৩: বাটনের ব্যাকগ্রাউন্ড কালার থিমের সাথে ম্যাচ করে আকর্ষণীয় করা হয়েছে
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8C9EFF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(context, {
                              'docId': docId,
                              'code': coupon['code'],
                              'discountType': coupon['discountType'],
                              'value': couponValue,
                              'minOrder': minOrderValue,
                            });
                          },
                          child: const Text(
                            "USE",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Text(
                      coupon['discountType'] == "Amount" || coupon['discountType'] == "Amount (Tk)"
                          ? "${couponValue.toStringAsFixed(0)} Tk Discount"
                          : "${couponValue.toStringAsFixed(0)}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _customChip(
                          coupon['couponType'] ?? "Reward",
                          const Color(0xFFE8EAF6),
                          const Color(0xFF3F51B5),
                        ),
                        _customChip(
                          "ACTIVE",
                          const Color(0xFFE8F5E9),
                          const Color(0xFF2E7D32),
                        ),
                        _customChip(
                          "REWARD",
                          const Color(0xFFFFF3E0),
                          const Color(0xFFE65100),
                        ),
                        _customChip(
                          getRemainingDay(coupon['endDate']),
                          const Color(0xFFFFEBEE),
                          const Color(0xFFB71C1C),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _customChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CouponOfferScreen extends StatefulWidget {
  const CouponOfferScreen({super.key});

  @override
  State<CouponOfferScreen> createState() => _CouponOfferScreenState();
}

class _CouponOfferScreenState extends State<CouponOfferScreen> {
  String _currentUserId = "";
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceUserId();
  }

  Future<void> _loadDeviceUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('device_user_id') ?? "default_guest";
      _isLoadingUser = false;
    });
  }

  bool isCouponLiveAndActive(dynamic startData, dynamic endData, bool adminStatus) {
    if (adminStatus == false) return false;
    if (endData == null) return true;

    try {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      DateTime end = (endData as Timestamp).toDate();
      DateTime endDate = DateTime(end.year, end.month, end.day);

      if (startData != null) {
        DateTime start = (startData as Timestamp).toDate();
        DateTime startDate = DateTime(start.year, start.month, start.day);
        if (today.isBefore(startDate)) return false;
      }

      if (today.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint("Coupon date parsing error: $e");
      return false;
    }
  }

  String getRemainingDay(dynamic endDateData) {
    if (endDateData == null) return "NO LIMIT";

    try {
      DateTime expiry = (endDateData as Timestamp).toDate();
      DateTime now = DateTime.now();

      DateTime expiryOnlyDate = DateTime(expiry.year, expiry.month, expiry.day);
      DateTime nowOnlyDate = DateTime(now.year, now.month, now.day);
      Duration difference = expiryOnlyDate.difference(nowOnlyDate);

      if (difference.isNegative) {
        return "EXPIRED";
      } else if (difference.inDays == 0) {
        return "EXPIRES TODAY";
      } else if (difference.inDays == 1) {
        return "1 DAY LEFT";
      } else {
        return "${difference.inDays} DAYS LEFT";
      }
    } catch (e) {
      return "N/A";
    }
  }

  void markCouponsAsRead(List<QueryDocumentSnapshot> docs, String currentUserId) {
    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List viewedUsers = data['viewedBy'] ?? [];
      if (!viewedUsers.contains(currentUserId)) {
        doc.reference.update({
          'viewedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Coupon Offer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade50,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50, // আপনার সেই লাইট ব্যাকগ্রাউন্ড UI
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_coupons')
            .where('userId', isEqualTo: _currentUserId)
            .where('status', isEqualTo: 'available')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No coupons available.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // 🔥 FIXED FILTER: এখানে আমরা চেক করছি ডেট ঠিক আছে কিনা + কুপনটি লিমিটের বেশি ইউজ করা হয়েছে কিনা
          var activeDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;

            int usedCount = data['usedCount'] ?? 0;
            int perUserLimit = data['perUserLimit'] ?? 1;

            // যদি কুপনটি অলরেডি লিমিট শেষ করে ফেলে, তবে লিস্টে আসবে না
            bool isLimitValid = usedCount < perUserLimit;
            bool isDateValid = isCouponLiveAndActive(data['startDate'], data['endDate'], true);

            return isLimitValid && isDateValid;
          }).toList();

          if (activeDocs.isEmpty) {
            return const Center(
              child: Text(
                "No active coupon found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            markCouponsAsRead(activeDocs, _currentUserId);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            itemCount: activeDocs.length,
            itemBuilder: (context, index) {
              var doc = activeDocs[index];
              Map<String, dynamic> coupon = doc.data() as Map<String, dynamic>;
              String docId = doc.id;

              double couponValue = 0.0;
              if (coupon['value'] != null) {
                couponValue = (coupon['value'] is int)
                    ? (coupon['value'] as int).toDouble()
                    : (coupon['value'] as double);
              }

              double minOrderValue = 0.0;
              if (coupon['minOrder'] != null) {
                minOrderValue = (coupon['minOrder'] is int)
                    ? (coupon['minOrder'] as int).toDouble()
                    : (coupon['minOrder'] as double);
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF212121), // আপনার সেই ডার্ক কার্ড UI
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          coupon['code'] ?? "CODE",
                          style: const TextStyle(
                            color: Color(0xFF8C9EFF),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8C9EFF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            // ✅ ফিক্স: কার্ট স্ক্রিনের ফায়ারবেস আপডেটের সুবিধার জন্য 'id' কি-তে docId পাস করা হলো
                            Navigator.pop(context, {
                              'id': docId,
                              'code': coupon['code'],
                              'discountType': coupon['discountType'],
                              'value': couponValue,
                              'minOrder': minOrderValue,
                            });
                          },
                          child: const Text(
                            "USE",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Text(
                      coupon['discountType'] == "Amount" || coupon['discountType'] == "Amount (Tk)"
                          ? "${couponValue.toStringAsFixed(0)} Tk Discount"
                          : "${couponValue.toStringAsFixed(0)}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _customChip(
                          coupon['couponType'] ?? "Reward",
                          const Color(0xFFE8EAF6),
                          const Color(0xFF3F51B5),
                        ),
                        _customChip(
                          "ACTIVE",
                          const Color(0xFFE8F5E9),
                          const Color(0xFF2E7D32),
                        ),
                        _customChip(
                          "LIMIT : ${coupon['perUserLimit']}",
                          const Color(0xFFFFF3E0),
                          const Color(0xFFE65100),
                        ),
                        _customChip(
                          getRemainingDay(coupon['endDate']),
                          const Color(0xFFFFEBEE),
                          const Color(0xFFB71C1C),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _customChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}