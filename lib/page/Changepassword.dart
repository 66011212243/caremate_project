
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangepasswordPage extends StatefulWidget {
  final String sid;

  const ChangepasswordPage({
    super.key,
    this.sid = "naw5Oe3VyaVwj89isnzA",
  });

  @override
  State<ChangepasswordPage> createState() => _ChangepasswordPageState();
}

class _ChangepasswordPageState extends State<ChangepasswordPage> {
  // Controllers
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // สถานะการทำงาน
  bool isLoading = false;

  // แสดง/ซ่อนรหัสผ่าน
  bool hideOldPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // แสดงข้อความ
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // เปลี่ยนรหัสผ่าน
  Future<void> _changePassword() async {
    if (isLoading) return;

    final oldPassword = oldPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    // ตรวจสอบข้อมูล
    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }

    // ตรวจสอบรหัสผ่านใหม่ตรงกัน
    if (newPassword != confirmPassword) {
      _showMessage('รหัสผ่านใหม่ไม่ตรงกัน');
      return;
    }

    // ตรวจสอบความยาว
    if (newPassword.length < 8) {
      _showMessage('รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }

    // ตรวจสอบว่าไม่ได้ใช้รหัสผ่านเดิม
    if (oldPassword == newPassword) {
      _showMessage('รหัสผ่านใหม่ต้องไม่เหมือนรหัสผ่านเดิม');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ผู้ใช้ที่กำลัง Login อยู่
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
        return;
      }

      // ตรวจสอบว่า sid เป็นของผู้ใช้ที่ Login อยู่จริง
      if (user.uid != widget.sid) {
        _showMessage('ไม่พบข้อมูลบัญชีผู้ใช้');
        return;
      }

      // ตรวจสอบว่าเป็นบัญชี Email/Password
      final hasEmailPasswordProvider = user.providerData.any(
        (provider) => provider.providerId == 'password',
      );

      if (!hasEmailPasswordProvider) {
        _showMessage(
          'บัญชีนี้เข้าสู่ระบบด้วย Google จึงไม่สามารถเปลี่ยนรหัสผ่านจากหน้านี้ได้',
        );
        return;
      }

      // ตรวจสอบว่ามี Email
      if (user.email == null || user.email!.isEmpty) {
        _showMessage('ไม่พบอีเมลของผู้ใช้');
        return;
      }

      // ตรวจสอบรหัสผ่านเก่า
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // เปลี่ยนรหัสผ่านใหม่
      await user.updatePassword(newPassword);

      if (!mounted) return;

      // ล้างข้อมูลในช่องกรอก
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      _showMessage('เปลี่ยนรหัสผ่านสำเร็จ');

      // รอให้เห็นข้อความก่อนกลับหน้าเดิม
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      // ส่ง true กลับไปหน้าก่อนหน้า
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'รหัสผ่านเก่าไม่ถูกต้อง';
          break;

        case 'weak-password':
          message = 'รหัสผ่านใหม่ไม่ปลอดภัยเพียงพอ';
          break;

        case 'requires-recent-login':
          message = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
          break;

        case 'network-request-failed':
          message = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้';
          break;

        case 'too-many-requests':
          message = 'มีการลองมากเกินไป กรุณารอสักครู่';
          break;

        case 'user-disabled':
          message = 'บัญชีผู้ใช้นี้ถูกระงับการใช้งาน';
          break;

        case 'user-not-found':
          message = 'ไม่พบข้อมูลผู้ใช้';
          break;

        case 'operation-not-allowed':
          message = 'ยังไม่ได้เปิดใช้งาน Email/Password ใน Firebase';
          break;

        default:
          message = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
      }

      if (mounted) {
        _showMessage(message);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ช่องกรอกรหัสผ่าน
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggle,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: !isLoading,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(
            color: Colors.grey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: isLoading ? null : onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: isLoading
              ? null
              : () => Navigator.pop(context),
        ),
        title: const Text(
          'เปลี่ยนรหัสผ่าน',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.lock_reset,
                size: 70,
                color: Colors.red,
              ),

              const SizedBox(height: 15),

              const Text(
                'เปลี่ยนรหัสผ่านใหม่',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'กรุณากรอกรหัสผ่านเดิมและรหัสผ่านใหม่',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              // รหัสผ่านเก่า
              _buildPasswordField(
                controller: oldPasswordController,
                hintText: 'รหัสผ่านเก่า',
                obscureText: hideOldPassword,
                prefixIcon: Icons.lock,
                onToggle: () {
                  setState(() {
                    hideOldPassword = !hideOldPassword;
                  });
                },
              ),

              const SizedBox(height: 16),

              // รหัสผ่านใหม่
              _buildPasswordField(
                controller: newPasswordController,
                hintText: 'รหัสผ่านใหม่',
                obscureText: hideNewPassword,
                prefixIcon: Icons.lock_outline,
                onToggle: () {
                  setState(() {
                    hideNewPassword = !hideNewPassword;
                  });
                },
              ),

              const SizedBox(height: 16),

              // ยืนยันรหัสผ่านใหม่
              _buildPasswordField(
                controller: confirmPasswordController,
                hintText: 'ยืนยันรหัสผ่านใหม่',
                obscureText: hideConfirmPassword,
                prefixIcon: Icons.lock_outline,
                onToggle: () {
                  setState(() {
                    hideConfirmPassword = !hideConfirmPassword;
                  });
                },
              ),

              const SizedBox(height: 12),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '* รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ปุ่มยืนยัน
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : _changePassword,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
