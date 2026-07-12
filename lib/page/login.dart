import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/register_provider.dart';
import 'package:caremate_application/page/register_service.dart';
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
                  backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  loginUser();
                },
                child: const Text("เข้าสู่ระบบ"),
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
                  MaterialPageRoute(builder: (context) => RegisterService()),
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
                  MaterialPageRoute(builder: (context) => RegisterProvider()),
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
    log(emailInput);
    var indexRef = db.collection('service');
    var dbPro = db.collection('provider');

    var query = indexRef.where("email", isEqualTo: emailInput);
    var result = await query.get();

    var queryPro = dbPro.where("email", isEqualTo: emailInput);
    var resultPro = await queryPro.get();

    if (result.docs.isNotEmpty) {
      var userDoc = result.docs.first;
      var userData = userDoc.data();
      var hashedPassword = userData['password'];
      var userId = userDoc.id;
      log("user_id $userId");

      bool userIsMatch = BCrypt.checkpw(
        passwordController.text,
        hashedPassword,
      );

      if (userIsMatch) {
        setState(() {
          isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomepageService(sid: userId)),
        );
      } else {
        log('รหัสผ่านผิด');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("รหัสผ่านไม่ถูกต้อง"),
            content: const Text("รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง"),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    isLoading = false;
                  });
                  Navigator.of(context).pop(); // ปิด dialog
                },
                child: const Text("ปิด"),
              ),
            ],
          ),
        );
      }
    } else if (resultPro.docs.isNotEmpty) {
      var userDoc = resultPro.docs.first;
      var userData = userDoc.data();
      var hashedPassword = userData['password'];
      var userId = userDoc.id;
      log("user_id $userId");
      bool userIsMatch = BCrypt.checkpw(
        passwordController.text,
        hashedPassword,
      );
      if (userIsMatch) {
        setState(() {
          isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageProvider(pid: userId),
          ),
        );
      } else {
        log('รหัสผ่านผิด');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("รหัสผ่านไม่ถูกต้อง"),
            content: const Text("รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง"),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    isLoading = false;
                  });
                  Navigator.of(context).pop(); // ปิด dialog
                },
                child: const Text("ปิด"),
              ),
            ],
          ),
        );
      }
    } else {
      log('ไม่มีบัญชีนี้');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("ไม่มีบัญชีนี้"),
          content: const Text("ไม่มีบัญชีนี้ กรุณาลองใหม่อีกครั้ง"),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  isLoading = false;
                });
                Navigator.of(context).pop(); // ปิด dialog
              },
              child: const Text("ปิด"),
            ),
          ],
        ),
      );
    }
  }
}

