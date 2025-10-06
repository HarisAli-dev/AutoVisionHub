import 'package:hive_flutter/adapters.dart';

class HiveUtils {
  static Box getSessionBox() {
    return Hive.box('sessionBox');
  }

  static Future<bool> putData(String key, dynamic value) async {
    final box = getSessionBox();
    await box.put(key, value);
    return true;
  }

  //login logout token
  static Future<bool> loginSession() async {
    final box = getSessionBox();
    await box.put('isLoggedIn', true);
    return true;
  }

  static Future<bool> logOutSession() async {
    final box = getSessionBox();

    // Clear all user session data
    await box.put('isLoggedIn', false);
    await box.delete('userId');
    await box.delete('name');
    await box.delete('token');
    await box.delete('role');

    // Clear any other session-related data
    await box.delete('fcm_token');

    return true;
  }

  static dynamic getData(String key) {
    final box = getSessionBox();
    return box.get(key);
  }
}
