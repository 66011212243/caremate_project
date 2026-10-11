import 'package:caremate_application/page/accountStatusPage.dart';
import 'package:caremate_application/page/auth_navigation.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

Future<void> signInWithGoogle(
  BuildContext context, {
  required VoidCallback onLoadingStart,
  required VoidCallback onLoadingEnd,
}) async {
  final db = FirebaseFirestore.instance;

  onLoadingStart();

  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    // 1. เลือก Google Account
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) return;

    // 2. ดึงข้อมูล Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Login Firebase Authentication
    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    final User? user = userCredential.user;

    if (user == null) return;

    log('Google UID: ${user.uid}');
    log('Google Email: ${user.email}');

    // 4. ค้นหาข้อมูลผู้ใช้ใน Firestore
    final userDoc = await db.collection('users').doc(user.uid).get();

    // 5. ไม่พบบัญชี
    if (!userDoc.exists) {
      Fluttertoast.showToast(msg: 'ไม่พบบัญชีนี้ กรุณาสมัครสมาชิกก่อน');

      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();

      return;
    }

    // 6. อ่านข้อมูลผู้ใช้
    final userData = userDoc.data()!;
    final String userId = userDoc.id;
    final int role = userData['role'] as int;

    log('User UID: $userId');
    log('User Role: $role');

    if (!context.mounted) return;

    // 7. แยก Role
    if (role == 0) {
      onLoadingEnd();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomepageService(uid: userId)),
        (route) => false,
      );
    } else if (role == 1) {
      onLoadingEnd();

      await navigateAfterLogin(context: context, uid: userId, role: role);
    } else if (role == 2) {
      onLoadingEnd();

      // TODO: นำทางไปหน้า Admin
      log('เข้าสู่ระบบ Admin');
    } else {
      Fluttertoast.showToast(msg: 'ประเภทบัญชีไม่ถูกต้อง');

      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();
    }
  } catch (e) {
    log('Google login error: $e');

    Fluttertoast.showToast(msg: 'เข้าสู่ระบบไม่สำเร็จ');
  } finally {
    onLoadingEnd();
  }
}
