import 'dart:developer';

import 'package:caremate_application/page/login.dart';
import 'package:caremate_application/page/register_service_google.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class RegisterService extends StatefulWidget {
  const RegisterService({super.key});

  @override
  State<RegisterService> createState() => _RegisterServiceState();
}

class _RegisterServiceState extends State<RegisterService> {
  final emailCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final confirmCtl = TextEditingController();
  final usernameCtl = TextEditingController();
  final fullnameCtl = TextEditingController();

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
              "สมัครสมาชิก",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 0, 0),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: TextField(
                controller: usernameCtl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'ชื่อผู้ใช้',
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: TextField(
                controller: fullnameCtl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'ชื่อ-สกุล',
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: TextField(
                controller: emailCtl,
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
                controller: passwordCtl,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'รหัสผ่าน',
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              child: TextField(
                controller: confirmCtl,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  hintText: 'ยืนยันรหัสผ่าน',
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
                  register();
                },
                child: const Text("ลงทะเบียน"),
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
                  registerWithGoogle(context);
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => LoginPage()),
                  // );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //Image.asset('assets/images/google.png', width: 20),
                    const SizedBox(width: 10),
                    const Text("สมัครด้วย Google"),
                  ],
                ),
              ),
            ),
          ],
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
      if (usernameCtl.text.isEmpty ||
          fullnameCtl.text.isEmpty ||
          emailCtl.text.isEmpty ||
          passwordCtl.text.isEmpty ||
          confirmCtl.text.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบ")));
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (!isValidEmail(emailCtl.text)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("รูปแบบอีเมลไม่ถูกต้อง")));
        return;
      }

      if (passwordCtl.text != confirmCtl.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")));
        return;
      }
      if (!isStrongPassword(passwordCtl.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "รหัสผ่านต้องมีอย่างน้อย 8 ตัว และต้องมีตัวพิมพ์ใหญ่ พิมพ์เล็ก และตัวเลข",
            ),
          ),
        );
        return;
      }
      var docRef = db.collection('service').doc();

      final hashedPassword = BCrypt.hashpw(passwordCtl.text, BCrypt.gensalt());

      var data = {
        'nickname': usernameCtl.text,
        'name': fullnameCtl.text,
        'email': emailCtl.text,
        'password': hashedPassword,
      };

      await docRef.set(data);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Error: $e");
    }
  }
}
