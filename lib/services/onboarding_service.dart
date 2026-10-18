import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  // ตรวจสอบว่าเคยดูหน้าแนะนำหรือยัง
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  // บันทึกว่าเคยดูหน้าแนะนำแล้ว
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('hasSeenOnboarding', true);
  }
}