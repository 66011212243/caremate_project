import 'package:caremate_application/page/app_session.dart';
import 'package:caremate_application/page/auth_navigation.dart';
import 'package:caremate_application/page/homepage_admin.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/login.dart';
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
    final session = await AppSession.get();
    if (!mounted) return;

    if (session == null) {
      _goLogin();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(session.uid)
          .get();

      // บัญชีถูกลบไปแล้ว
      if (!doc.exists) {
        await AppSession.clear();
        _goLogin();
        return;
      }

      final data = doc.data()!;
      final role = data['role'] as int;
      // ถ้ามีสถานะที่ห้ามเข้า เช็กตรงนี้ เช่น
      // if (data['status_account'] == 'banned') { ... }

      if (!mounted) return;
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
          _goLogin();
      }
    } catch (e) {
      // ออฟไลน์หรือโหลดไม่ได้ จะให้เข้าด้วยค่าที่จำไว้ หรือไปหน้า Login ก็ได้
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
