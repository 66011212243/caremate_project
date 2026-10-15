import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const _kUid = 'uid';
  static const _kRole = 'role';

  static Future<void> save(String uid, int role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUid, uid);
    await prefs.setInt(_kRole, role);
  }

  static Future<({String uid, int role})?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kUid);
    final role = prefs.getInt(_kRole);
    if (uid == null || role == null) return null;
    return (uid: uid, role: role);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
