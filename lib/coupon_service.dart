
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'main.dart';

class CouponService {
  static final CouponService _instance = CouponService._internal();
  factory CouponService() => _instance;
  CouponService._internal();

  bool _isLockActive = false;
  StreamSubscription<QuerySnapshot>? _orderSubscription;

  bool _isAmountType(String minOrderType) {
    String n = minOrderType.toLowerCase().trim();
    return n == 'amount (tk)' || n == 'amount' || n == 'amount(tk)' || n == 'tk';
  }

  bool _isCountType(String minOrderType) {
    String n = minOrderType.toLowerCase().trim();
    return n == 'order count' || n == 'order' || n == 'count' || n == 'ordercount';
  }

  Future<String> _getDeviceUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('device_user_id');
    if (storedId == null) {
      var uuid = const Uuid();
      storedId = 'guest_${uuid.v4()}';
      await prefs.setString('device_user_id', storedId);
    }
    return storedId;
  }

  void startListeningToOrders() async {
    final String targetUser = await _getDeviceUserId();
    debugPrint("🔍 [COUPON SERVICE] Listener started for User: $targetUser");

    _orderSubscription?.cancel();

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: targetUser)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        var orderData = doc.data();
        String docId = doc.id;

        if (orderData['couponChecked'] == null || orderData['couponChecked'] == false) {
          FirebaseFirestore.instance.collection('orders').doc(docId).update({'couponChecked': true});
          _checkAndRewardCoupon(docId, targetUser);
        }
      }
    });
  }

  Future<void> _checkAndRewardCoupon(String orderId, String targetUser) async {
    if (_isLockActive) return;
    _isLockActive = true;

    try {
      DocumentSnapshot freshOrderSnap = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (!freshOrderSnap.exists) return;

      Map<String, dynamic> currentOrderData = freshOrderSnap.data() as Map<String, dynamic>;
      double currentOrderPrice = 0.0;
      if (currentOrderData['totalPrice'] != null) {
        currentOrderPrice = (currentOrderData['totalPrice'] is int)
            ? (currentOrderData['totalPrice'] as int).toDouble()
            : (currentOrderData['totalPrice'] as double);
      }

      QuerySnapshot adminCoupons = await FirebaseFirestore.instance.collection('coupons').where('status', isEqualTo: true).get();
      final DateTime now = DateTime.now();

      for (var doc in adminCoupons.docs) {
        var coupon = doc.data() as Map<String, dynamic>;
        String couponId = doc.id;

        String couponType = (coupon['couponType'] ?? '').toString().toLowerCase().trim();
        String couponCode = coupon['couponCode'] ?? '';
        String couponName = coupon['couponName'] ?? 'Reward';
        int perUserLimit = coupon['perUserLimit'] ?? 1;
        String minOrderType = (coupon['minOrderType'] ?? '').toString().trim();

        double minOrderValue = 0.0;
        var rawMinOrder = coupon['minOrder'] ?? coupon['minOrderValue'];
        if (rawMinOrder != null) {
          minOrderValue = (rawMinOrder is int) ? rawMinOrder.toDouble() : (rawMinOrder as double);
        }

        DateTime? startDate;
        DateTime? endDate;
        try {
          if (coupon['startDate'] != null) startDate = (coupon['startDate'] as Timestamp).toDate();
          if (coupon['endDate'] != null) endDate = (coupon['endDate'] as Timestamp).toDate();
        } catch (e) {
          continue;
        }

        if (couponType != 'new') {
          if (startDate == null || endDate == null) continue;
          bool isWithinDateRange = now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
          if (!isWithinDateRange) continue;
        }

        QuerySnapshot existingRewards = await FirebaseFirestore.instance
            .collection('user_coupons')
            .where('userId', isEqualTo: targetUser)
            .where('couponId', isEqualTo: couponId)
            .get();

        if (existingRewards.docs.length >= perUserLimit) continue;

        bool isConditionMatched = false;

        switch (couponType) {
          case 'new':
            QuerySnapshot newUserOrders = await FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: targetUser).where('status', isEqualTo: 'accepted').get();
            if (newUserOrders.docs.length == 1) isConditionMatched = true;
            break;

          case 'regular':
          case 'vip':
          case 'special':
          case 'festival':
          default:
            QuerySnapshot matchedOrders = await FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: targetUser)
                .where('status', isEqualTo: 'accepted')
                .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!))
                .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate!.add(const Duration(days: 1))))
                .get();

            if (_isAmountType(minOrderType)) {
              for (var orderDoc in matchedOrders.docs) {
                double singleOrderPrice = 0.0;
                var data = orderDoc.data() as Map<String, dynamic>;

                if (data['totalPrice'] != null) {
                  singleOrderPrice = (data['totalPrice'] is int) ? (data['totalPrice'] as int).toDouble() : (data['totalPrice'] as double);
                }

                if (singleOrderPrice >= minOrderValue) {
                  isConditionMatched = true;
                  break;
                }
              }
            } else if (_isCountType(minOrderType)) {
              if (matchedOrders.docs.length >= minOrderValue.toInt()) {
                isConditionMatched = true;
              }
            }
            break;
        }

        if (isConditionMatched) {
          double discVal = 0.0;
          var rawDisc = coupon['discountValue'] ?? coupon['value'];
          if (rawDisc != null) {
            discVal = (rawDisc is int) ? rawDisc.toDouble() : (rawDisc as double);
          }

          await FirebaseFirestore.instance.collection('user_coupons').add({
            'userId': targetUser,
            'couponId': couponId,
            'code': couponCode,
            'title': couponName,
            'couponType': couponType,
            'status': 'available',
            'discountType': coupon['discountType'] ?? 'Amount',
            'value': discVal,
            'minOrder': minOrderValue,
            'minOrderType': minOrderType, // কার্ট স্ক্রিন হ্যান্ডেল করার জন্য জরুরি
            'perUserLimit': perUserLimit,
            'usedCount': 0,
            'startDate': coupon['startDate'],
            'endDate': coupon['endDate'],
            'createdAt': FieldValue.serverTimestamp(),
          });

          final BuildContext? globalContext = navigatorKey.currentState?.context;
          if (globalContext != null) {
            _showGlobalSuccessDialog(globalContext, couponType, couponCode, perUserLimit);
          }
          break;
        }
      }
    } catch (e) {
      debugPrint("💥 Global Coupon reward error: $e");
    } finally {
      _isLockActive = false;
    }
  }

  void _showGlobalSuccessDialog(BuildContext context, String couponType, String couponCode, int perUserLimit) {
    bool isClaimed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              backgroundColor: const Color(0xFF212121),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_membership, color: Color(0xFF8C9EFF), size: 60),
                    const SizedBox(height: 15),
                    const Text("CONGRATULATIONS! 🎉", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("You unlocked a ${couponType.toUpperCase()} coupon!", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF8C9EFF), width: 1.5),
                      ),
                      child: Text(couponCode, style: const TextStyle(color: Color(0xFF8C9EFF), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 12),

                    // 🛑 অরেঞ্জ কালারের লিমিট ইউজেস ব্যাজ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.orange, width: 0.8),
                      ),
                      child: Text(
                        "Usage Limit: $perUserLimit ${perUserLimit > 1 ? 'Times' : 'Time'}",
                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isClaimed ? Colors.grey : const Color(0xFF8C9EFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: isClaimed
                            ? null
                            : () {
                          setDialogState(() => isClaimed = true);
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("🎁 Coupon $couponCode Claimed!"),
                            backgroundColor: Colors.green.shade700,
                          ));
                        },
                        child: Text(isClaimed ? "PROCESSING..." : "CLAIM NOW", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void stopListening() {
    _orderSubscription?.cancel();
  }
}