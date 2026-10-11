import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class ChangepasswordPage extends StatefulWidget {
  final String userId; // UID ของเอกสารใน users

  const ChangepasswordPage({super.key, required this.userId});

  @override
  State<ChangepasswordPage> createState() => _ChangepasswordPageState();
}

class _ChangepasswordPageState extends State<ChangepasswordPage> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hideOldPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  // ชื่อฟิลด์รหัสผ่านที่เป็นไปได้
  static const List<String> _passwordKeys = [
    'password',
    'pass',
    'passwd',
    'pwd',
    'user_password',
  ];

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ดึงเอกสาร users ด้วย uid (ลอง Document ID ก่อน แล้วลอง field uid)
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserDocument(
    String uid,
  ) async {
    final fs = FirebaseFirestore.instance;

    final doc = await fs.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      debugPrint('พบ users/$uid');
      return doc;
    }

    final q = await fs
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      debugPrint('พบ users จาก field uid = $uid');
      return q.docs.first;
    }

    debugPrint('ไม่พบ users ด้วย uid = $uid');
    return null;
  }

  String? _findPasswordKey(Map<String, dynamic> data) {
    for (final key in _passwordKeys) {
      final v = data[key]?.toString();
      if (v != null && v.isNotEmpty) return key;
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (isLoading) return;

    final uid = widget.userId.trim();
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (uid.isEmpty) {
      _showMessage('ไม่พบรหัสผู้ใช้งาน (uid ว่าง)');
      return;
    }

    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('รหัสผ่านใหม่ไม่ตรงกัน');
      return;
    }

    if (newPassword.length < 8) {
      _showMessage('รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }

    if (oldPassword == newPassword) {
      _showMessage('รหัสผ่านใหม่ต้องไม่เหมือนรหัสผ่านเดิม');
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. ค้นหา users
      final userDoc = await _findUserDocument(uid);
      final userData = userDoc?.data();

      if (userDoc == null || userData == null) {
        _showMessage('ไม่พบข้อมูลผู้ใช้ใน users');
        return;
      }

      debugPrint('USER DOC ID = ${userDoc.id}');
      debugPrint('USER KEYS = ${userData.keys.toList()}');

      // 2. หาฟิลด์รหัสผ่าน
      final passwordKey = _findPasswordKey(userData);
      if (passwordKey == null) {
        _showMessage(
          'ไม่พบฟิลด์รหัสผ่านใน users/${userDoc.id}\n'
          'ฟิลด์ที่มี: ${userData.keys.join(', ')}',
        );
        return;
      }

      final currentPassword = userData[passwordKey].toString();

      // 3. ตรวจรหัสเดิม (รองรับ bcrypt และข้อความธรรมดา)
      final isBcrypt = RegExp(r'^\$2[abxy]\$').hasMatch(currentPassword);
      bool passwordCorrect = false;

      if (isBcrypt) {
        try {
          passwordCorrect = BCrypt.checkpw(oldPassword, currentPassword);
        } catch (e) {
          debugPrint('BCrypt Error: $e');
        }
      } else {
        passwordCorrect = oldPassword == currentPassword;
      }

      if (!passwordCorrect) {
        _showMessage('รหัสผ่านเดิมไม่ถูกต้อง');
        return;
      }

      // 4. แฮชรหัสใหม่แล้วบันทึกที่ฟิลด์เดิม
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await userDoc.reference.update({passwordKey: hashedPassword});

      if (!mounted) return;

      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      _showMessage('เปลี่ยนรหัสผ่านสำเร็จ');

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} / ${e.message}');

      String message;
      switch (e.code) {
        case 'permission-denied':
          message = 'ไม่มีสิทธิ์แก้ไขข้อมูล กรุณาตรวจสอบ Firebase Rules';
          break;
        case 'unavailable':
          message = 'ไม่สามารถเชื่อมต่อฐานข้อมูลได้';
          break;
        case 'not-found':
          message = 'ไม่พบข้อมูลผู้ใช้ใน Firebase';
          break;
        default:
          message = 'เกิดข้อผิดพลาด: ${e.message ?? e.code}';
      }
      _showMessage(message);
    } catch (e) {
      debugPrint('Change Password Error: $e');
      _showMessage('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'เปลี่ยนรหัสผ่าน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              const Icon(Icons.lock_reset, size: 70, color: Colors.red),
              const SizedBox(height: 15),
              const Text(
                'เปลี่ยนรหัสผ่านใหม่',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'กรุณากรอกรหัสผ่านเดิมและรหัสผ่านใหม่',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              _buildPasswordField(
                controller: oldPasswordController,
                hintText: 'รหัสผ่านเดิม',
                obscureText: hideOldPassword,
                prefixIcon: Icons.lock,
                onToggle: () =>
                    setState(() => hideOldPassword = !hideOldPassword),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: newPasswordController,
                hintText: 'รหัสผ่านใหม่',
                obscureText: hideNewPassword,
                prefixIcon: Icons.lock_outline,
                onToggle: () =>
                    setState(() => hideNewPassword = !hideNewPassword),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: confirmPasswordController,
                hintText: 'ยืนยันรหัสผ่านใหม่',
                obscureText: hideConfirmPassword,
                prefixIcon: Icons.lock_outline,
                onToggle: () =>
                    setState(() => hideConfirmPassword = !hideConfirmPassword),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '* รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 35),
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
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: isLoading ? null : _changePassword,
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