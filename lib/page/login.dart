import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/notification_system.dart';
import 'package:caremate_application/page/register_provider.dart';
import 'package:caremate_application/page/register_service.dart';
import 'package:caremate_application/page/register_users.dart';
import 'package:caremate_application/page/signIn_Google.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:developer';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'caremate',
      theme: ThemeData(fontFamily: 'Prompt'),
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var db = FirebaseFirestore.instance;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/caremateV2.png',
              width: 350,
              height: 150,
              fit: BoxFit.contain,
            ),

            const Text(
              "เข้าสู่ระบบ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 0, 0),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'อีเมล',
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'รหัสผ่าน',
                ),
              ),
            ),

            SizedBox(
              width: 300,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoading
                      ? Colors.grey
                      : const Color.fromARGB(255, 255, 0, 0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : loginUser,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("เข้าสู่ระบบ"),
              ),
            ),

            const SizedBox(height: 15),
            const Text(
              "หรือ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 0, 0),
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
                onPressed: () {
                  signInWithGoogle(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //Image.asset('assets/images/google.png', width: 20),
                    const SizedBox(width: 10),
                    const Text("เข้าสู่ระบบด้วย Google"),
                  ],
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterUsers(role: 0),
                  ),
                );
              },
              child: const Text(
                'สมัครเป็นผู้รับบริการ',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 0, 0),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.red,
                  decorationThickness: 2,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterUsers(role: 1),
                  ),
                );
              },
              child: const Text(
                'สมัครเป็นผู้ให้บริการ',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 0, 0),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.red,
                  decorationThickness: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void loginUser() async {
    setState(() {
      isLoading = true;
    });

    var emailInput = emailController.text.trim();
    var passwordInput = passwordController.text;

    log("Login email: $emailInput");

    try {
      // ค้นหาผู้ใช้จาก users collection
      var query = db.collection('users').where('email', isEqualTo: emailInput);

      var result = await query.get();

      // ไม่พบบัญชี
      if (result.docs.isEmpty) {
        log('ไม่มีบัญชีนี้');

        setState(() {
          isLoading = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("ไม่มีบัญชีนี้"),
            content: const Text("ไม่มีบัญชีนี้ กรุณาลองใหม่อีกครั้ง"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("ปิด"),
              ),
            ],
          ),
        );

        return;
      }

      // ข้อมูลผู้ใช้
      var userDoc = result.docs.first;
      var userData = userDoc.data();

      var userId = userDoc.id;
      var hashedPassword = userData['password'];
      var role = userData['role'];

      log("user_id: $userId");
      log("role: $role");

      // ตรวจสอบรหัสผ่าน
      bool userIsMatch = BCrypt.checkpw(passwordInput, hashedPassword);

      // รหัสผ่านไม่ถูกต้อง
      if (!userIsMatch) {
        log('รหัสผ่านผิด');

        setState(() {
          isLoading = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("รหัสผ่านไม่ถูกต้อง"),
            content: const Text("รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("ปิด"),
              ),
            ],
          ),
        );

        return;
      }

      // --------------------------------
      // Login สำเร็จ
      // --------------------------------

      log("Login สำเร็จ");

      setState(() {
        isLoading = false;
      });

      // --------------------------------
      // ตรวจสอบ Role
      // --------------------------------

      if (role == 0) {
        // ผู้รับบริการ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomepageService(uid: userId)),
        );
      } else if (role == 1) {
        // ผู้ให้บริการ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageProvider(uid: userId),
          ),
        );
      } else if (role == 2) {
        // แอดมิน
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const HomepageAdmin(),
        //   ),
        // );
      } else {
        // Role ไม่ถูกต้อง
        log("ไม่พบ Role ที่รองรับ: $role");

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("เกิดข้อผิดพลาด"),
            content: const Text("ไม่พบประเภทบัญชีที่ถูกต้อง"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("ปิด"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      log("Login error: $e");

      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาด"),
          content: Text("ไม่สามารถเข้าสู่ระบบได้\n$e"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("ปิด"),
            ),
          ],
        ),
      );
    }
  }
}
