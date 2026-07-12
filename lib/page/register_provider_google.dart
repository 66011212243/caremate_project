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

Future<void> registerProviderWithGoogle(BuildContext context) async {
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
      await FirebaseFirestore.instance.collection("provider").doc(user.uid).set(
        {"email": user.email, "realname": user.displayName},
      );

      Fluttertoast.showToast(msg: "สมัครสมาชิกสำเร็จ");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomepageProvider(pid: user.uid),
        ),
      );
    }
  } catch (e) {
    print(e);
    Fluttertoast.showToast(msg: "Register failed");
  }
}
