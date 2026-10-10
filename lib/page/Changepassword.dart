import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class ChangepasswordPage extends StatefulWidget {
  // UID ของ users โดยตรง
  final String? userId;

  // ID ของผู้รับบริการ
  final String? sid;

  // ID ของผู้ให้บริการ
  final String? pid;

  const ChangepasswordPage({
    super.key,
    this.userId,
    this.sid,
    this.pid,
  });

  @override
  State<ChangepasswordPage> createState() => _ChangepasswordPageState();
}

class _ChangepasswordPageState extends State<ChangepasswordPage> {
  // =========================
  // Controllers
  // =========================

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  // แสดง / ซ่อนรหัสผ่าน
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

  // =========================
  // แสดงข้อความ
  // =========================

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

  // =========================================================
  // ค้นหา users
  // =========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findUserDocument() async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('==============================');
    debugPrint('เริ่มค้นหาผู้ใช้');
    debugPrint('userId = ${widget.userId}');
    debugPrint('sid = ${widget.sid}');
    debugPrint('pid = ${widget.pid}');
    debugPrint('==============================');

    String? targetUid = widget.userId?.trim();

    // =========================================================
    // 1. กรณีมี userId มาโดยตรง
    // =========================================================

    if (targetUid != null && targetUid.isNotEmpty) {
      debugPrint('ค้นหาจาก userId โดยตรง: $targetUid');
    }

    // =========================================================
    // 2. กรณีเป็นผู้รับบริการ
    // =========================================================

    else if (widget.sid != null && widget.sid!.trim().isNotEmpty) {
      final sid = widget.sid!.trim();

      debugPrint('กำลังค้นหา service sid = $sid');

      // 2.1 sid เป็น Document ID
      final serviceDoc =
          await firestore.collection('service').doc(sid).get();

      if (serviceDoc.exists && serviceDoc.data() != null) {
        targetUid = serviceDoc.data()?['service_uid']?.toString();

        debugPrint(
          'พบ service จาก Document ID',
        );
        debugPrint(
          'service_uid = $targetUid',
        );
      }

      // 2.2 ถ้า sid ไม่ใช่ Document ID
      else {
        debugPrint(
          'ไม่พบ service/$sid กำลังค้นหาจาก service_id',
        );

        final serviceResult = await firestore
            .collection('service')
            .where('service_id', isEqualTo: sid)
            .limit(1)
            .get();

        if (serviceResult.docs.isNotEmpty) {
          targetUid =
              serviceResult.docs.first.data()['service_uid']?.toString();

          debugPrint(
            'พบ service จาก service_id',
          );
          debugPrint(
            'service_uid = $targetUid',
          );
        }
      }
    }

    // =========================================================
    // 3. กรณีเป็นผู้ให้บริการ
    // =========================================================

    else if (widget.pid != null && widget.pid!.trim().isNotEmpty) {
      final pid = widget.pid!.trim();

      debugPrint('กำลังค้นหา provider pid = $pid');

      // 3.1 pid เป็น Document ID
      final providerDoc =
          await firestore.collection('provider').doc(pid).get();

      if (providerDoc.exists && providerDoc.data() != null) {
        targetUid =
            providerDoc.data()?['provider_uid']?.toString();

        debugPrint(
          'พบ provider จาก Document ID',
        );
        debugPrint(
          'provider_uid = $targetUid',
        );
      }

      // 3.2 ถ้า pid ไม่ใช่ Document ID
      else {
        debugPrint(
          'ไม่พบ provider/$pid กำลังค้นหาจาก pid',
        );

        final providerResult = await firestore
            .collection('provider')
            .where('pid', isEqualTo: pid)
            .limit(1)
            .get();

        if (providerResult.docs.isNotEmpty) {
          targetUid =
              providerResult.docs.first.data()['provider_uid']?.toString();

          debugPrint(
            'พบ provider จากฟิลด์ pid',
          );
          debugPrint(
            'provider_uid = $targetUid',
          );
        }
      }
    }

    // =========================================================
    // 4. ตรวจสอบ UID
    // =========================================================

    if (targetUid == null || targetUid.isEmpty) {
      debugPrint('ไม่พบ UID ของผู้ใช้');

      return null;
    }

    debugPrint(
      'กำลังค้นหา users ด้วย UID = $targetUid',
    );

    // =========================================================
    // 5. ค้นหา users จาก Document ID
    // =========================================================

    final userDoc =
        await firestore.collection('users').doc(targetUid).get();

    if (userDoc.exists) {
      debugPrint(
        'พบ users/$targetUid',
      );

      return userDoc;
    }

    // =========================================================
    // 6. ถ้า UID ไม่ใช่ Document ID
    //    ลองค้นหาจาก field uid
    // =========================================================

    debugPrint(
      'ไม่พบ users/$targetUid',
    );

    final userQueryResult = await firestore
        .collection('users')
        .where('uid', isEqualTo: targetUid)
        .limit(1)
        .get();

    if (userQueryResult.docs.isNotEmpty) {
      debugPrint(
        'พบ users จาก field uid',
      );

      return userQueryResult.docs.first;
    }

    debugPrint(
      'ไม่พบข้อมูลผู้ใช้ใน users',
    );

    return null;
  }

  // =========================================================
  // เปลี่ยนรหัสผ่าน
  // =========================================================

  Future<void> _changePassword() async {
    if (isLoading) return;

    final oldPassword =
        oldPasswordController.text.trim();

    final newPassword =
        newPasswordController.text.trim();

    final confirmPassword =
        confirmPasswordController.text.trim();

    // =========================================================
    // ตรวจสอบข้อมูล
    // =========================================================

    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบทุกช่อง');
      return;
    }

    // =========================================================
    // ตรวจสอบว่ามี ID อย่างน้อย 1 ตัว
    // =========================================================

    if ((widget.userId == null || widget.userId!.trim().isEmpty) &&
        (widget.sid == null || widget.sid!.trim().isEmpty) &&
        (widget.pid == null || widget.pid!.trim().isEmpty)) {
      _showMessage('ไม่พบรหัสผู้ใช้งาน');
      return;
    }

    // =========================================================
    // ตรวจสอบรหัสผ่านใหม่
    // =========================================================

    if (newPassword != confirmPassword) {
      _showMessage('รหัสผ่านใหม่ไม่ตรงกัน');
      return;
    }

    // =========================================================
    // ตรวจสอบความยาว
    // =========================================================

    if (newPassword.length < 8) {
      _showMessage(
        'รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัวอักษร',
      );
      return;
    }

    // =========================================================
    // ตรวจสอบว่าไม่ใช้รหัสเดิม
    // =========================================================

    if (oldPassword == newPassword) {
      _showMessage(
        'รหัสผ่านใหม่ต้องไม่เหมือนรหัสผ่านเดิม',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // =======================================================
      // 1. ค้นหา users
      // =======================================================

      final userDoc = await _findUserDocument();

      if (userDoc == null) {
        _showMessage('ไม่พบข้อมูลผู้ใช้');
        return;
      }

      // =======================================================
      // 2. อ่านข้อมูล users
      // =======================================================

      final userData = userDoc.data();

      if (userData == null) {
        _showMessage('ไม่พบข้อมูลผู้ใช้');
        return;
      }

      // =======================================================
      // 3. อ่าน password เดิม
      // =======================================================

      final currentPassword =
          userData['password']?.toString();

      if (currentPassword == null ||
          currentPassword.isEmpty) {
        _showMessage('ไม่พบรหัสผ่านของผู้ใช้');
        return;
      }

      // =======================================================
      // 4. ตรวจสอบ password เดิมด้วย BCrypt
      // =======================================================

      bool passwordCorrect = false;

      try {
        passwordCorrect = BCrypt.checkpw(
          oldPassword,
          currentPassword,
        );
      } catch (e) {
        debugPrint(
          'BCrypt Error: $e',
        );

        passwordCorrect = false;
      }

      if (!passwordCorrect) {
        _showMessage('รหัสผ่านเดิมไม่ถูกต้อง');
        return;
      }

      // =======================================================
      // 5. Hash password ใหม่
      // =======================================================

      final hashedPassword = BCrypt.hashpw(
        newPassword,
        BCrypt.gensalt(),
      );

      // =======================================================
      // 6. บันทึกรหัสผ่านใหม่
      // =======================================================

      await userDoc.reference.update({
        'password': hashedPassword,
      });

      debugPrint(
        'เปลี่ยนรหัสผ่านสำเร็จ',
      );

      // =======================================================
      // 7. ล้างข้อมูล
      // =======================================================

      if (!mounted) return;

      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      _showMessage('เปลี่ยนรหัสผ่านสำเร็จ');

      // รอให้เห็นข้อความ
      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase Error: ${e.code}',
      );
      debugPrint(
        'Firebase Message: ${e.message}',
      );

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'permission-denied':
          message =
              'ไม่มีสิทธิ์แก้ไขข้อมูล กรุณาตรวจสอบ Firebase Rules';
          break;

        case 'unavailable':
          message =
              'ไม่สามารถเชื่อมต่อฐานข้อมูลได้';
          break;

        case 'not-found':
          message =
              'ไม่พบข้อมูลผู้ใช้ใน Firebase';
          break;

        default:
          message =
              'เกิดข้อผิดพลาด: ${e.message ?? e.code}';
      }

      _showMessage(message);
    } catch (e) {
      debugPrint(
        'Change Password Error: $e',
      );

      if (mounted) {
        _showMessage(
          'เกิดข้อผิดพลาด: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // ช่องกรอกรหัสผ่าน
  // =========================================================

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
          onPressed:
              isLoading ? null : onToggle,
        ),
      ),
    );
  }

  // =========================================================
  // UI
  // =========================================================

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

              // รหัสผ่านเดิม
              _buildPasswordField(
                controller: oldPasswordController,
                hintText: 'รหัสผ่านเดิม',
                obscureText: hideOldPassword,
                prefixIcon: Icons.lock,
                onToggle: () {
                  setState(() {
                    hideOldPassword =
                        !hideOldPassword;
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
                    hideNewPassword =
                        !hideNewPassword;
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
                    hideConfirmPassword =
                        !hideConfirmPassword;
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
                    disabledBackgroundColor:
                        Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(25),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
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
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ยืนยัน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
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