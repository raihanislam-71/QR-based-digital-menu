// // import 'package:digital_manu/firebase_options.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_dotenv/flutter_dotenv.dart';
// // import 'deep_linking.dart';
// // import 'home_screen.dart';
// // import 'loading_screen.dart';
//
// // // এটি গ্লোবালি ডিক্লেয়ার করুন যাতে যেকোনো ফাইল থেকে অ্যাক্সেস করা যায়
// // final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
//
// //   await Firebase.initializeApp(
// //     options: DefaultFirebaseOptions.currentPlatform,
// //   );
//
// //   await dotenv.load(fileName: ".env");
// //   runApp(MyApp());
// // }
//
// // class MyApp extends StatelessWidget{
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(
// //         primarySwatch: Colors.orange,
// //         scaffoldBackgroundColor: Colors.grey.shade50,
// //       ),
// //       navigatorKey: navigatorKey,
// //       home: const HomeScreen(),
// //       // home: LoadingScreen(),
// //       // home: DeepLinking(),
// //     );
// //   }
// // }
//
// import 'package:digital_manu/firebase_options.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'deep_linking.dart';
// import 'home_screen.dart';
// import 'loading_screen.dart';
//
// // এটি গলোবালি ডিক্লেয়ার করুন যাতে যেকোনো ফাইল থেকে অ্যাক্সেস করা যায়
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
// // অ্যাপ একদম বন্ধ (Closed) থাকলে নোটিফিকেশন রিসিভ করার ব্যাকগ্রাউন্ড ফাংশন
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   print("Background Notification Received: ${message.messageId}");
// }
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   // ব্যাকগ্রাউন্ড মেসেজ হ্যান্ডলার রেজিস্টার করা
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//   // নোটিফিকেশনের পারমিশন এবং সেটিংস নেওয়া
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//
//   NotificationSettings settings = await messaging.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );
//
//   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//     print('User granted notification permission');
//
//     // ইউজারকে 'all_users' টপিকে সাবস্ক্রাইব করানো
//     await messaging.subscribeToTopic('all_users');
//     print('Subscribed to all_users topic');
//   }
//
//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//     alert: true,
//     badge: true,
//     sound: true,
//   );
//
//   // 🔥 ADDED FOR FOREGROUND: অ্যাপ ওপেন থাকা অবস্থায় নোটিফিকেশন স্ক্রিনে পপ-আপ করার লজিক
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     RemoteNotification? notification = message.notification;
//     if (notification != null) {
//       // গ্লোবাল navigatorKey ব্যবহার করে কারেন্ট স্ক্রিনের কনটেক্সট (Context) নেওয়া হচ্ছে
//       final context = navigatorKey.currentContext;
//       if (context != null) {
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             title: Row(
//               children: [
//                 const Icon(Icons.card_giftcard, color: Colors.orange, size: 28), // কুপনের সাথে ম্যাচিং আইকন
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     notification.title ?? "🎁 New Offer!",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ],
//             ),
//             content: Text(notification.body ?? ""),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   "Awesome!",
//                   style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ],
//           ),
//         );
//       }
//     }
//   });
//
//   await dotenv.load(fileName: ".env");
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget{
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.orange,
//         scaffoldBackgroundColor: Colors.grey.shade50,
//       ),
//       navigatorKey: navigatorKey, // এটি ডায়ালগটি দেখানোর জন্য মাস্ট লাগবে
//       home: const HomeScreen(),
//     );
//   }
// }
//
//
//


import 'package:digital_manu/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // kIsWeb এর জন্য প্রয়োজন
import 'deep_linking.dart';
import 'home_screen.dart';

// 🌟 ১. গ্লোবাল নেভিগেটর কি (যাতে অন্য ফাইল থেকেও অ্যাক্সেস করা যায়)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🌟 ২. ব্যাকগ্রাউন্ড মেসেজ হ্যান্ডলার ফাংশন (অবশ্যই main ফাংশনের বাইরে থাকতে হবে)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Background Notification Received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ৩. ওয়েবে যেন ক্র্যাশ না করে, তাই !kIsWeb কন্ডিশন
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted notification permission');

    // ৪. টপিক সাবস্ক্রিপশন শুধু মোবাইলের জন্য
    if (!kIsWeb) {
      await messaging.subscribeToTopic('all_users');
      print('Subscribed to all_users topic');
    }
  }

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // ৫. Foreground Message Listener (অ্যাপ ওপেন থাকা অবস্থায় নোটিফিকেশন)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(notification.title ?? "🎁 New Offer!"),
            content: Text(notification.body ?? ""),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Awesome!", style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
      }
    }
  });

  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

// 🌟 ৬. MyApp ক্লাস (সব ব্র্যাকেট ঠিক করা হয়েছে)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      navigatorKey: navigatorKey, // গ্লোবাল কি এখানে সেট করা হয়েছে
      home: HomeScreen(),
      // home: DeepLinking(),
    );
  }
}

