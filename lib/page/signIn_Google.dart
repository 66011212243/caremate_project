import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    User? user = userCredential.user;

    if (user != null) {
      String email = user.email ?? "";

      // เช็คผู้ให้บริการ
      var serviceQuery = await FirebaseFirestore.instance
          .collection("service")
          .where("email", isEqualTo: email)
          .get();

      // เช็คผู้รับบริการ
      var providerQuery = await FirebaseFirestore.instance
          .collection("provider")
          .where("email", isEqualTo: email)
          .get();

      if (serviceQuery.docs.isNotEmpty) {
        // เป็นผู้ให้บริการ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageService(sid: user.uid),
          ),
        );
      } else if (providerQuery.docs.isNotEmpty) {
        // เป็นผู้รับบริการ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageProvider(pid: user.uid),
          ),
        );
      } else {
        // ไม่มีในระบบ
        Fluttertoast.showToast(msg: "กรุณาสมัครสมาชิกก่อน");

        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      }
    }
  } catch (e) {
    print("Google login error: $e");
    Fluttertoast.showToast(msg: "Login failed");
  }
}
