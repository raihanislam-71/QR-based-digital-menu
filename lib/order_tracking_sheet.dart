/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingSheet extends StatefulWidget {
  final String tableNumber;
  const OrderTrackingSheet({super.key, required this.tableNumber});

  @override
  State<OrderTrackingSheet> createState() => _OrderTrackingSheetState();
}

class _OrderTrackingSheetState extends State<OrderTrackingSheet> {

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('orders').doc(orderId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 50, height: 5,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Active Orders (Table: ${widget.tableNumber})",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('tableNumber', isEqualTo: widget.tableNumber)
                  .where('status', whereIn: ['panding', 'accepted']) // ডাটাবেজ স্পেলিং অনুযায়ী ঠিক আছে
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No active orders",
                          style: TextStyle(color: Colors.grey)));
                }

                var orders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var orderDoc = orders[index];
                    var orderData = orderDoc.data() as Map<String, dynamic>;
                    String docId = orderDoc.id;
                    var status = orderData['status'] ?? 'panding';
                    var items = orderData['item'] as List? ?? [];
                    var estimatedTime = orderData['estimatedTime'] ?? '';

                    Color cardColor = status == 'panding'
                        ? const Color.fromARGB(255, 255, 254, 230)
                        : const Color.fromARGB(255, 224, 245, 226);

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status: ${status.toString().toUpperCase()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'panding'
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                            if (estimatedTime.isNotEmpty && status != 'panding')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("Estimated time: $estimatedTime",
                                    style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold)),
                              ),
                            const Divider(),
                            ...items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${item['name']}"),
                                  Text("x ${item['quantity']}")
                                ],
                              ),
                            )),
                            if (status == 'panding') ...[
                              const Divider(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  onPressed: () => _showCancelDialog(context, docId),
                                  child: const Text("Cancel order"),
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



*/
/*

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingSheet extends StatefulWidget {
  final String tableNumber;
  const OrderTrackingSheet({super.key, required this.tableNumber});

  @override
  State<OrderTrackingSheet> createState() => _OrderTrackingSheetState();
}

class _OrderTrackingSheetState extends State<OrderTrackingSheet> {

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('orders').doc(orderId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 50, height: 5,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Active Orders (Table: ${widget.tableNumber})",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('tableNumber', isEqualTo: widget.tableNumber)
                  .where('status', whereIn: ['panding', 'accepted'])
                  // .orderBy('createdAt', descending: true) // নতুন order সবার উপরে
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No active orders",
                          style: TextStyle(color: Colors.grey)));
                }

                var orders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var orderDoc = orders[index];
                    var orderData = orderDoc.data() as Map<String, dynamic>;
                    String docId = orderDoc.id;
                    var status = orderData['status'] ?? 'panding';
                    var items = orderData['item'] as List? ?? [];
                    var estimatedTime = orderData['estimatedTime'] ?? '';

                    // নতুন order (index == 0) হলে বিশেষ border দিয়ে highlight করা
                    bool isNewest = index == 0;

                    Color cardColor = status == 'panding'
                        ? const Color.fromARGB(255, 255, 254, 230)
                        : const Color.fromARGB(255, 224, 245, 226);

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isNewest
                            ? const BorderSide(color: Colors.orange, width: 2)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // নতুন order badge
                            if (isNewest)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "🆕 Latest Order",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            Text(
                              "Status: ${status.toString().toUpperCase()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'panding'
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                            if (estimatedTime.isNotEmpty && status != 'panding')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("Estimated time: $estimatedTime",
                                    style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold)),
                              ),
                            const Divider(),
                            ...items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${item['name']}"),
                                  Text("x ${item['quantity']}")
                                ],
                              ),
                            )),
                            if (status == 'panding') ...[
                              const Divider(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  onPressed: () => _showCancelDialog(context, docId),
                                  child: const Text("Cancel order"),
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
*//*



*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTrackingSheet extends StatefulWidget {
  final String tableNumber;
  const OrderTrackingSheet({super.key, required this.tableNumber});

  @override
  State<OrderTrackingSheet> createState() => _OrderTrackingSheetState();
}

class _OrderTrackingSheetState extends State<OrderTrackingSheet> {

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('orders').doc(orderId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _sortOrders(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      // createdAt field দিয়ে sort (cart_screen.dart এ এই নামে save হয়)
      if (aData['createdAt'] != null && bData['createdAt'] != null) {
        final aTime = aData['createdAt'] as Timestamp;
        final bTime = bData['createdAt'] as Timestamp;
        return bTime.compareTo(aTime);
      }
      return b.id.compareTo(a.id);
    });
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 50, height: 5,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Active Orders (Table: ${widget.tableNumber})",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  // .where('tableNumber', isEqualTo: widget.tableNumber)
                  .where('status', whereIn: ['panding', 'accepted'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No active orders",
                          style: TextStyle(color: Colors.grey)));
                }

                // Client-side sort — নতুন order সবার উপরে
                var orders = _sortOrders(snapshot.data!.docs.toList());

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var orderDoc = orders[index];
                    var orderData = orderDoc.data() as Map<String, dynamic>;
                    String docId = orderDoc.id;
                    var status = orderData['status'] ?? 'panding';
                    var items = orderData['item'] as List? ?? [];
                    var estimatedTime = orderData['estimatedTime'] ?? '';
                    var unavailableMessage = orderData['unavailableMessage'] ?? '';
                    var totalPrice = orderData['totalPrice'] ?? '';


                    Color cardColor = status == 'panding'
                        ? const Color.fromARGB(255, 255, 254, 230)
                        : const Color.fromARGB(255, 224, 245, 226);

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status: ${status.toString().toUpperCase()}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: status == 'panding'
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                            if (estimatedTime.isNotEmpty && status != 'panding')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("Estimated time: $estimatedTime",
                                    style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold)),
                              ),

                            if (unavailableMessage.isNotEmpty && status != 'panding')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("$unavailableMessage",
                                    style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold)),
                              ),

                            const Divider(),
                            ...items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${item['name']}"),
                                  Text("x ${item['quantity']}")
                                ],
                              ),
                            )),

                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // বামে প্রাইস, ডানে বাটন রাখবে
                                children: [
                                  // 💵 এই টেক্সটটি অর্ডার PENDING বা ACCEPTED যাই হোক না কেন, সবসময় দেখাবে
                                  Text(
                                    "Total: $totalPrice Tk",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),

                                  // ❌ ক্যানসেল বাটনটি শুধুমাত্র PENDING অবস্থায় দেখাবে, ACCEPTED হলে মুছে যাবে
                                  if (status == 'panding')
                                    OutlinedButton(
                                      onPressed: () => _showCancelDialog(context, docId),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.redAccent),
                                      ),
                                      child: const Text(
                                        "Cancel order",
                                        style: TextStyle(color: Colors.redAccent),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
