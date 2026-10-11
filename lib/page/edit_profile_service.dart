import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EditProfileService extends StatefulWidget {
  final String sid;

  const EditProfileService({super.key, this.sid = "5n4H3wdcrI7M4mI6F7iG"});

  @override
  State<EditProfileService> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfileService> {
  // Controllers สำหรับช่องพิมพ์แก้ไข
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  String? selectedGender;
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  bool isEditing = true;
  bool isLoading = true;
  bool isSaving = false;

  File? profileImageFile;
  String? currentProfileImageUrl;
  String? uid;
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
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลเดิมจาก Firebase
  Future<void> _fetchProfileData() async {
    try {
      // 1. ดึงข้อมูลจาก collection 'provider' ด้วย pid
      DocumentSnapshot providerDoc = await FirebaseFirestore.instance
          .collection('service')
          .doc(widget.sid)
          .get();

      if (providerDoc.exists && providerDoc.data() != null) {
        Map<String, dynamic> providerData =
            providerDoc.data() as Map<String, dynamic>;

        phoneController.text = providerData['phone']?.toString() ?? '';
        weightController.text = providerData['weight']?.toString() ?? '';
        heightController.text = providerData['height']?.toString() ?? '';
        final gender = providerData['gender'];

        if (gender == 1 || gender == '1') {
          selectedGender = '1';
        } else if (gender == 0 || gender == '0') {
          selectedGender = '0';
        } else {
          selectedGender = null;
        }
        currentProfileImageUrl = providerData['profile']?.toString();
        uid = providerData['service_uid']
            ?.toString(); // ดึง uid ที่เชื่อมกับ users

        // 2. ดึงข้อมูลจาก collection 'users' ตาม service_uid
        if (uid != null && uid!.isNotEmpty) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            nameController.text = userData['realname']?.toString() ?? '';
            usernameController.text = userData['username']?.toString() ?? '';
          }
        }
      }

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        profileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      const cloudName = "dsz1hhnx4";
      const uploadPreset = "flutter_upload";

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        return jsonData['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // บันทึกข้อมูลลง Firestore
  // บันทึกการแก้ไข
  Future<void> _saveProfile() async {
    debugPrint('========== เริ่มบันทึก ==========');
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();
    final gender = selectedGender;
    final height = heightController.text.trim();
    final weight = weightController.text.trim();

    if (name.isEmpty || username.isEmpty || phone.isEmpty || gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบทุกช่อง'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      String? imageUrl = currentProfileImageUrl;

      if (profileImageFile != null) {
        String? uploadedUrl = await uploadToCloudinary(profileImageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          throw Exception('อัปโหลดรูปภาพไม่สำเร็จ');
        }
      }

      // อัปเดตตาราง 'users' (realname, username)
      if (uid != null && uid!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'realname': name,
          'username': username,
        });
      }

      // อัปเดตตาราง 'provider' (phoneNo, gender, profile)
      await FirebaseFirestore.instance
          .collection('service')
          .doc(widget.sid)
          .update({
            'phone': phone,
            'gender': int.parse(gender),
            'height': height,
            'weight': weight,
            if (imageUrl != null) 'profile': imageUrl,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลโปรไฟล์สำเร็จ!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
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
                              isEditing: isEditing,
                              isGender: true,
                              selectedGender: selectedGender,
                              onGenderChanged: (value) {
                                setState(() {
                                  selectedGender = value;
                                });
                              },
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
  final TextEditingController? controller;
  final bool isEditing;
  final bool isNumber;
  final bool isGender;

  final String? selectedGender;
  final ValueChanged<String?>? onGenderChanged;

  const ProfileRow({
    super.key,
    required this.title,
    this.controller,
    required this.isEditing,
    this.isNumber = false,
    this.isGender = false,
    this.selectedGender,
    this.onGenderChanged,
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
                ? isGender
                      ? DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                          hint: const Text('เลือกเพศ'),
                          items: const [
                            DropdownMenuItem(value: '0', child: Text('ชาย')),
                            DropdownMenuItem(value: '1', child: Text('หญิง')),
                          ],
                          onChanged: onGenderChanged,
                        )
                      : TextFormField(
                          controller: controller,
                          keyboardType: isNumber
                              ? TextInputType.phone
                              : TextInputType.text,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: UnderlineInputBorder(),
                          ),
                        )
                : Text(
                    isGender
                        ? (selectedGender == '1'
                              ? 'หญิง'
                              : selectedGender == '0'
                              ? 'ชาย'
                              : '-')
                        : (controller?.text.isEmpty ?? true)
                        ? '-'
                        : controller!.text,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
          ),
        ],
      ),
    );
  }
}
