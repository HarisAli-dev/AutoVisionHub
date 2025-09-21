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
    await box.put('isLoggedIn', false);
    return true;
  }

  static dynamic getData(String key) {
    final box = getSessionBox();
    return box.get(key);
  }
}