import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    // -----------------------------
    // เลือก Google Account
    // -----------------------------

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) return;

    // -----------------------------
    // ดึงข้อมูล Google
    // -----------------------------

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // -----------------------------
    // Login Firebase Authentication
    // -----------------------------

    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    final User? user = userCredential.user;

    if (user == null) return;

    log("Google UID: ${user.uid}");
    log("Google Email: ${user.email}");

    // -----------------------------
    // ค้นหาข้อมูลใน users
    // -----------------------------

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // -----------------------------
    // ไม่มีบัญชีในระบบ
    // -----------------------------

    if (!userDoc.exists) {
      Fluttertoast.showToast(msg: "ไม่พบบัญชีนี้ กรุณาสมัครสมาชิกก่อน");

      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();

      return;
    }

    // -----------------------------
    // ดึงข้อมูลผู้ใช้
    // -----------------------------

    final userData = userDoc.data()!;

    final int role = userData['role'];

    log("User UID: ${user.uid}");
    log("User Role: $role");

    // -----------------------------
    // Role 0 = ผู้รับบริการ
    // -----------------------------

    if (role == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomepageService(uid: user.uid)),
      );
    }
    // -----------------------------
    // Role 1 = ผู้ให้บริการ
    // -----------------------------
    else if (role == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomepageProvider(uid: user.uid),
        ),
      );
    }
    // -----------------------------
    // Role 2 = Admin
    // -----------------------------
    else if (role == 2) {
      // TODO: ไปหน้า Admin
      log("เข้าสู่ระบบ Admin");
    }
    // -----------------------------
    // Role ไม่ถูกต้อง
    // -----------------------------
    else {
      Fluttertoast.showToast(msg: "ประเภทบัญชีไม่ถูกต้อง");

      await FirebaseAuth.instance.signOut();
      await googleSignIn.signOut();
    }
  } catch (e) {
    log("Google login error: $e");

    Fluttertoast.showToast(msg: "เข้าสู่ระบบไม่สำเร็จ");
  }
}
