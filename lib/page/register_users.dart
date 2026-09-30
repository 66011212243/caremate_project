import 'dart:developer';

import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/login.dart';
import 'package:caremate_application/page/register_service_google.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterUsers extends StatefulWidget {
  final int role;

  const RegisterUsers({super.key, required this.role});

  @override
  State<RegisterUsers> createState() => _RegisterUsersState();
}

class _RegisterUsersState extends State<RegisterUsers> {
  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  final usernameCtl = TextEditingController();
  final fullnameCtl = TextEditingController();

  final db = FirebaseFirestore.instance;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/caremateV2.png',
                width: 350,
                height: 150,
                fit: BoxFit.contain,
              ),

              if (widget.role == 0)
                const Text(
                  "สมัครสมาชิกเป็นผู้รับบริการ",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 0, 0),
                  ),
                ),
              if (widget.role == 1)
                const Text(
                  "สมัครสมาชิกเป็นผู้ให้บริการ",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 0, 0),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                child: TextField(
                  controller: usernameCtl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    hintText: 'ชื่อผู้ใช้',
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                child: TextField(
                  controller: fullnameCtl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    hintText: 'ชื่อ-สกุล',
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                child: TextField(
                  controller: emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    hintText: 'อีเมล',
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                child: TextField(
                  controller: passwordCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    hintText: 'รหัสผ่าน',
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 16,
                ),
                child: TextField(
                  controller: confirmCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    hintText: 'ยืนยันรหัสผ่าน',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: 300,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isLoading ? null : register,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("ลงทะเบียน"),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: 300,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    foregroundColor: const Color.fromARGB(255, 255, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          registerWithGoogle();
                        },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [SizedBox(width: 10), Text("สมัครด้วย Google")],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');

    return regex.hasMatch(email);
  }

  bool isStrongPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$',
    );

    return regex.hasMatch(password);
  }

  Future<void> register() async {
    log("register started");

    setState(() {
      isLoading = true;
    });

    try {
      final username = usernameCtl.text.trim();
      final fullname = fullnameCtl.text.trim();
      final email = emailCtl.text.trim();
      final password = passwordCtl.text;
      final confirmPassword = confirmCtl.text;
      final int role = widget.role;
      final int statusAccount = role == 1 ? 0 : 1;

      // ตรวจสอบข้อมูล
      if (username.isEmpty ||
          fullname.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));

        setState(() {
          isLoading = false;
        });

        return;
      }

      if (!isValidEmail(email)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("รูปแบบอีเมลไม่ถูกต้อง")));

        setState(() {
          isLoading = false;
        });

        return;
      }

      if (password != confirmPassword) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")));

        setState(() {
          isLoading = false;
        });

        return;
      }

      if (!isStrongPassword(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "รหัสผ่านต้องมีอย่างน้อย 8 ตัว "
              "และต้องมีตัวพิมพ์ใหญ่ พิมพ์เล็ก และตัวเลข",
            ),
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      // เข้ารหัสรหัสผ่าน
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // สร้าง users document
      final userRef = db.collection('users').doc();

      final userData = {
        'username': username,
        'realname': fullname,
        'email': email,
        'password': hashedPassword,
        'role': role,
        'status_account': statusAccount,
      };

      // บันทึกข้อมูลลง users
      await userRef.set(userData);

      log("User created: ${userRef.id}");

      // ถ้าเป็นผู้ให้บริการ
      if (widget.role == 1) {
        final providerRef = db.collection('provider').doc();

        await providerRef.set({'provider_uid': userRef.id});

        log("Provider created: ${providerRef.id}");
      }
      // ถ้าเป็นผู้รับบริการ
      else if (widget.role == 0) {
        final serviceRef = db.collection('service').doc();

        await serviceRef.set({'service_uid': userRef.id});

        log("Service created: ${serviceRef.id}");
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("สมัครสมาชิกสำเร็จ")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      log("Register error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  Future<void> registerWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final db = FirebaseFirestore.instance;

      // -----------------------------
      // ตรวจว่ามี users นี้แล้วหรือยัง
      // -----------------------------

      final userRef = db.collection('users').doc(user.uid);
      final userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        await FirebaseAuth.instance.signOut();
        await googleSignIn.signOut();

        Fluttertoast.showToast(msg: "บัญชีนี้สมัครไว้แล้ว กรุณาเข้าสู่ระบบ");

        setState(() {
          isLoading = false;
        });

        return;
      }

      // -----------------------------
      // กำหนดสถานะบัญชี
      // -----------------------------

      int statusAccount = 1;

      // ผู้ให้บริการต้องรอ Admin อนุมัติ
      if (widget.role == 1) {
        statusAccount = 0;
      }

      // -----------------------------
      // สร้าง users
      // -----------------------------

      await userRef.set({
        'username': user.displayName ?? '',
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': widget.role,
        'status_account': statusAccount,
      });

      // -----------------------------
      // สร้างข้อมูลตาม Role
      // -----------------------------

      if (widget.role == 0) {
        // ============================
        // ผู้รับบริการ
        // ============================

        final serviceRef = db.collection('service').doc();

        await serviceRef.set({'service_uid': user.uid});

        log("สร้าง service สำเร็จ");
        log("sid: ${serviceRef.id}");

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        Fluttertoast.showToast(msg: "สมัครสมาชิกสำเร็จ");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageService(uid: user.uid),
          ),
        );
      } else if (widget.role == 1) {
        // ============================
        // ผู้ให้บริการ
        // ============================

        final providerRef = db.collection('provider').doc();

        await providerRef.set({'provider_uid': user.uid});

        log("สร้าง provider สำเร็จ");
        log("pid: ${providerRef.id}");

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageProvider(uid: user.uid),
          ),
        );
      }
    } catch (e) {
      log("Google Register Error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "สมัครสมาชิกไม่สำเร็จ");
    }
  }
}
