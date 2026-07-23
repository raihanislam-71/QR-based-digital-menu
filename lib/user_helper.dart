import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserHelper {
  static const String _userIdKey = 'device_user_id';

  // এই ফাংশনটি ডিভাইস আইডি রিটার্ন করবে। না থাকলে নতুন বানিয়ে সেভ করবে।
  static Future<String> getDeviceUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString(_userIdKey);

    if (storedId == null) {
      // একটি ইউনিক র্যান্ডম আইডি তৈরি করবে
      var uuid = const Uuid();
      storedId = 'guest_${uuid.v4()}';
      await prefs.setString(_userIdKey, storedId);
    }

    return storedId;
  }
}