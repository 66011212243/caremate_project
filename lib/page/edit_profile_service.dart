import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileService extends StatefulWidget {
  final String sid;

  const EditProfileService({super.key, this.sid = "naw5Oe3VyaVwj89isnzA"});

  @override
  State<EditProfileService> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfileService> {
  // Controllers สำหรับช่องพิมพ์แก้ไข
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final addressController = TextEditingController();

  bool isEditing = true;
  bool isLoading = true;
  bool isSaving = false;

  File? profileImageFile;
  String? currentProfileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    genderController.dispose();
    heightController.dispose();
    weightController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลเดิมจาก Firebase
  Future<void> _fetchProfileData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.sid)
          .get();

      DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
          .collection('service')
          .doc(widget.sid)
          .get();

      if (mounted) {
        setState(() {
          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            nameController.text =
                userData['realname']?.toString() ??
                userData['name']?.toString() ??
                '';
            usernameController.text =
                userData['username']?.toString() ??
                userData['nickname']?.toString() ??
                '';
          }

          if (serviceDoc.exists && serviceDoc.data() != null) {
            Map<String, dynamic> serviceData =
                serviceDoc.data() as Map<String, dynamic>;
            phoneController.text = serviceData['phone']?.toString() ?? '';
            genderController.text = serviceData['gender']?.toString() ?? '';
            heightController.text = serviceData['height']?.toString() ?? '';
            weightController.text = serviceData['weight']?.toString() ?? '';
            addressController.text = serviceData['address']?.toString() ?? '';
            currentProfileImageUrl = serviceData['profileImage']?.toString();
          }

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Edit Profile Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // เลือกรูปภาพจากเครื่อง
  Future<void> _pickImage() async {
    if (!isEditing) return;
    // บีบอัดรูปภาพให้ขนาดเล็กมากๆ เพื่อเก็บใน Firestore ได้โดยไม่เกินขีดจำกัด
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        profileImageFile = File(pickedFile.path);
      });
    }
  }

  // แปลงรูปภาพเป็น Base64 String เพื่อเก็บบน Firestore โดยไม่ต้องใช้ Storage
  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      return "data:image/jpeg;base64,$base64Image";
    } catch (e) {
      debugPrint("Base64 Convert Error: $e");
      return null;
    }
  }

  // บันทึกข้อมูลลง Firestore
  Future<void> _saveProfile() async {
    setState(() => isSaving = true);

    try {
      String? imageUrl = currentProfileImageUrl;

      // ถ้ามีการเลือกรูปใหม่ ให้แปลงเป็น Base64
      if (profileImageFile != null) {
        String? base64Str = await _convertImageToBase64(profileImageFile!);
        if (base64Str != null) {
          imageUrl = base64Str;
        }
      }

      // บันทึกลง collection 'user'
      await FirebaseFirestore.instance.collection('user').doc(widget.sid).set({
        'realname': nameController.text.trim(),
        'username': usernameController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // บันทึกลง collection 'service'
      await FirebaseFirestore.instance
          .collection('service')
          .doc(widget.sid)
          .set({
            'phone': phoneController.text.trim(),
            'gender': genderController.text.trim(),
            'height': heightController.text.trim(),
            'weight': weightController.text.trim(),
            'address': addressController.text.trim(),
            if (imageUrl != null) 'profileImage': imageUrl,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          isSaving = false;
          currentProfileImageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลโปรไฟล์สำเร็จ!')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // รูปโปรไฟล์
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: const [
                            BoxShadow(blurRadius: 3, color: Colors.black12),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: ClipOval(
                                child: profileImageFile != null
                                    ? Image.file(
                                        profileImageFile!,
                                        fit: BoxFit.cover,
                                        width: 140,
                                        height: 140,
                                      )
                                    : (currentProfileImageUrl != null &&
                                          currentProfileImageUrl!.isNotEmpty)
                                    ? (currentProfileImageUrl!.startsWith(
                                            'data:image',
                                          )
                                          ? Image.memory(
                                              base64Decode(
                                                currentProfileImageUrl!
                                                    .split(',')
                                                    .last,
                                              ),
                                              fit: BoxFit.cover,
                                              width: 140,
                                              height: 140,
                                            )
                                          : Image.network(
                                              currentProfileImageUrl!,
                                              fit: BoxFit.cover,
                                              width: 140,
                                              height: 140,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.person,
                                                    size: 90,
                                                    color: Colors.grey,
                                                  ),
                                            ))
                                    : const Icon(
                                        Icons.person,
                                        size: 90,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            if (isEditing)
                              const Positioned(
                                right: 10,
                                bottom: 10,
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 16,
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // การ์ดแสดง/แก้ไขข้อมูล
                    Card(
                      color: const Color.fromARGB(255, 255, 253, 253),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ProfileRow(
                              title: 'ชื่อ:',
                              controller: nameController,
                              isEditing: isEditing,
                            ),
                            const Divider(),
                            ProfileRow(
                              title: 'ชื่อผู้ใช้:',
                              controller: usernameController,
                              isEditing: isEditing,
                            ),
                            const Divider(),
                            ProfileRow(
                              title: 'เพศ:',
                              controller: genderController,
                              isEditing: isEditing,
                            ),
                            const Divider(),
                            ProfileRow(
                              title: 'โทรศัพท์:',
                              controller: phoneController,
                              isEditing: isEditing,
                              isNumber: true,
                            ),
                            const Divider(),
                            ProfileRow(
                              title: 'ส่วนสูง:',
                              controller: heightController,
                              isEditing: isEditing,
                            ),
                            const Divider(),
                            ProfileRow(
                              title: 'น้ำหนัก:',
                              controller: weightController,
                              isEditing: isEditing,
                            ),
                            const Divider(),
                            ProfileRow(
                              title: 'พิกัดที่อยู่ :',
                              controller: addressController,
                              isEditing: isEditing,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ปุ่มกด สลับระหว่าง "แก้ไขข้อมูล" กับ "บันทึก"
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving ? null : _saveProfile,
                        icon: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool isEditing;
  final bool isNumber;

  const ProfileRow({
    super.key,
    required this.title,
    required this.controller,
    required this.isEditing,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: isEditing
                ? TextFormField(
                    controller: controller,
                    keyboardType: isNumber
                        ? TextInputType.phone
                        : TextInputType.text,
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(),
                    ),
                  )
                : Text(
                    controller.text.isEmpty ? '-' : controller.text,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
          ),
        ],
      ),
    );
  }
}
