import 'package:caremate_application/page/app_session.dart';
import 'package:caremate_application/page/auth_navigation.dart';
import 'package:caremate_application/page/homepage_admin.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/landing_page.dart';
import 'package:caremate_application/page/login.dart';
import 'package:caremate_application/services/onboarding_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as SessionManager;

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      // 1. ตรวจสอบก่อนว่าเคยดูหน้าแนะนำแอปหรือยัง
      final hasSeen = await OnboardingService.hasSeenOnboarding();

      if (!mounted) return;

      // 2. ถ้ายังไม่เคยดูหน้าแนะนำ ให้ไปหน้า Onboarding
      if (!hasSeen) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
        return;
      }

      // 3. เคยดูหน้าแนะนำแล้ว จึงตรวจสอบ Session
      final session = await AppSession.get();

      if (!mounted) return;

      // 4. ไม่มี Session ให้ไปหน้า Login
      if (session == null) {
        _goLogin();
        return;
      }

      // 5. มี Session ให้ตรวจสอบข้อมูลบัญชีใน Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(session.uid)
          .get();

      if (!mounted) return;

      // บัญชีถูกลบไปแล้ว
      if (!doc.exists) {
        await AppSession.clear();

        if (!mounted) return;
        _goLogin();
        return;
      }

      final data = doc.data()!;
      final role = (data['role'] as num).toInt();

      // 6. ไปหน้าตาม Role เดิมของ CareMate
      switch (role) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomepageService(uid: session.uid),
            ),
          );
          break;

        case 1:
          await navigateAfterLogin(
            context: context,
            uid: session.uid,
            role: role,
          );
          break;

        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomepageAdmin(uid: session.uid)),
          );
          break;

        default:
          await AppSession.clear();

          if (!mounted) return;
          _goLogin();
      }
    } catch (e) {
      debugPrint('StartupGate error: $e');

      if (!mounted) return;

      // กรณีเกิดข้อผิดพลาดระหว่างตรวจสอบ
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
