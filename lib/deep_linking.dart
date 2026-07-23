import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class DeepLinking extends StatefulWidget {
  const DeepLinking({super.key});

  @override
  State<DeepLinking> createState() => _DeepLinkingState();
}

class _DeepLinkingState extends State<DeepLinking> {
  final appLinks = AppLinks();
  bool isScanned = false;

  final MobileScannerController controller = MobileScannerController(
    autoStart: false,
    formats: const[BarcodeFormat.qrCode],
  );

  @override
  void initState() {
    super.initState();
    initDeepLinks();

    // ২. Scanner start korar logic (Web stability-r jonno delayed kora)
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        // isStarting-er bodole direct start() call kora ekhon safe
        await controller.start();
      } catch (e) {
        print("Scanner start error: $e");
      }
    });
  }

  void initDeepLinks() async {
    // অ্যাপ যখন ব্যাকগ্রাউন্ডে থাকে তখন লিঙ্ক ধরার জন্য
    appLinks.uriLinkStream.listen((uri) {
      onQRScanned(uri.toString());
    });

    // অ্যাপ যখন একদম বন্ধ থাকে এবং লিঙ্কে ক্লিক করে ওপেন করা হয়
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      onQRScanned(initialLink.toString());
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ৩. টেবিল নম্বর সেভ করার মেইন লজিক
  void onQRScanned(String? code) async {
    // ২. চেক করুন অলরেডি স্ক্যান হয়েছে কি না
    if (isScanned || code == null) return;

    try {
      Uri uri = Uri.parse(code);
      if (uri.queryParameters.containsKey('table')) {
        String? tableNo = uri.queryParameters['table'];

        if (tableNo != null) {
          // ৩. স্ক্যান হওয়ার সাথে সাথে true করে দিন
          setState(() {
            isScanned = true;
          });

          // ৪. ক্যামেরা স্টপ করে দিন
          await controller.stop();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selected_table', tableNo);
          print("Table $tableNo saved!");

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      print("Invalid QR/Link: $e");
      // এরর হলে আবার স্ক্যান করার সুযোগ দিতে false করতে পারেন
      setState(() {
        isScanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture){
              final List<Barcode> barcodes = capture.barcodes;
              for(final barcode in barcodes){
                onQRScanned(barcode.rawValue);
              }
            },
          ),
          ColorFiltered(
            // Ekhane colorFilter property thikmoto use kora hoyeche
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                // Pura screen-e kalo layer
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                // Majhkhane shada box jeta "hole" toiri korbe
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scanner-er upore visual overlay ba message
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 40,
            right: 40,
            child: const Text(
              "Please scan the QR code located on your table to see the menu.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      )
    );
  }
}
