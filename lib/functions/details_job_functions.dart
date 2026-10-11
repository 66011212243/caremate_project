import 'dart:io';

import 'package:caremate_application/page/document.dart';
import 'package:flutter/material.dart';

const Color _kRed = Color.fromARGB(255, 255, 0, 0);

/// โครง dialog หัวสีแดง ใช้ร่วมกันทุกอัน
Future<void> _showRedDialog({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget content,
  required List<Widget> Function(BuildContext dialogContext) buildActions,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: _kRed,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: content,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: buildActions(dialogContext)),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showRedDialogHompage({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget content,
  required List<Widget> Function(BuildContext dialogContext) buildActions,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: _kRed,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: content,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: buildActions(dialogContext)),
            ),
          ],
        ),
      );
    },
  );
}

/// dialog ปุ่มเดียว (ตกลง)
Future<void> _showInfoDialog({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget content,
}) {
  return _showRedDialog(
    context: context,
    title: title,
    icon: icon,
    content: content,
    buildActions: (dialogContext) => [
      Expanded(
        child: ElevatedButton(
          style: _confirmStyle(),
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('ตกลง', style: TextStyle(fontSize: 18)),
        ),
      ),
    ],
  );
}

/// dialog สองปุ่ม (ไม่ใช่ / ยืนยัน)
Future<void> _showConfirmDialog({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget content,
  required Future<void> Function() onConfirm,
}) {
  return _showRedDialog(
    context: context,
    title: title,
    icon: icon,
    content: content,
    buildActions: (dialogContext) => [
      Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('ไม่ใช่', style: TextStyle(fontSize: 16)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          style: _confirmStyle(),
          onPressed: () async {
            Navigator.pop(dialogContext); // ปิด dialog ก่อน
            await onConfirm();
          },
          child: const Text('ยืนยัน', style: TextStyle(fontSize: 16)),
        ),
      ),
    ],
  );
}

ButtonStyle _confirmStyle() => ElevatedButton.styleFrom(
  backgroundColor: _kRed,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

// ===================== dialog ที่เรียกใช้จริง =====================

Future<void> showProviderIncompleteDialog(BuildContext context) {
  return _showInfoDialog(
    context: context,
    title: 'กรุณากรอกข้อมูลให้ครบ',
    icon: Icons.warning_amber_rounded,
    content: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ก่อนสมัครงาน กรุณากรอกข้อมูลต่อไปนี้ให้ครบถ้วน',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 12),
        Text('• เบอร์โทรศัพท์', style: TextStyle(fontSize: 16)),
        Text('• เพศ', style: TextStyle(fontSize: 16)),
        Text('• รูปโปรไฟล์', style: TextStyle(fontSize: 16)),
        Text('• ข้อมูลธนาคาร', style: TextStyle(fontSize: 16)),
        SizedBox(height: 12),
        Text(
          'เมื่อกรอกข้อมูลครบแล้ว จึงจะสามารถสมัครงานได้',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    ),
  );
}

Future<void> showVehicleMismatchDialog(BuildContext context) {
  return _showInfoDialog(
    context: context,
    title: 'ไม่สามารถสมัครงานได้',
    icon: Icons.directions_car,
    content: const Text(
      'คุณยังไม่สามารถรับงานนี้ได้ เนื่องจากประเภทยานพาหนะไม่ตรงกับที่งานต้องการ หรือเอกสารยานพาหนะยังไม่ได้รับการอนุมัติ\n\n'
      'กรุณาตรวจสอบประเภทรถและสถานะเอกสารของคุณ แล้วลองอีกครั้ง',

      style: TextStyle(fontSize: 16),
    ),
  );
}

Future<void> showCancelApplyDialog(
  BuildContext context, {
  required Future<void> Function() onConfirm,
}) {
  return _showConfirmDialog(
    context: context,
    title: 'ยกเลิกการสมัครงาน',
    icon: Icons.cancel_outlined,
    content: const Text(
      'คุณต้องการยกเลิกการสมัครงานนี้หรือไม่?',
      style: TextStyle(fontSize: 16),
    ),
    onConfirm: onConfirm,
  );
}

Future<void> showCancelJobDialog(
  BuildContext context, {
  required Future<void> Function() onConfirm,
}) {
  return _showConfirmDialog(
    context: context,
    title: 'ยืนยันการยกเลิกงาน',
    icon: Icons.warning_amber_rounded,
    content: RichText(
      text: const TextSpan(
        style: TextStyle(color: Colors.black, fontSize: 16),
        children: [
          TextSpan(
            text: 'ในแต่ละเดือนสามารถยกเลิกงานได้สูงสุด 3 งาน (0/3)\n\n',
          ),
          TextSpan(
            text: 'คุณต้องการยกเลิกงานนี้หรือไม่?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
    onConfirm: onConfirm,
  );
}

Future<void> showTimeMismatchDialog(BuildContext context) {
  return _showInfoDialog(
    context: context,
    title: 'ไม่สามารถสมัครงานได้',
    icon: Icons.directions_car,
    content: const Text(
      'ช่วงเวลาของงานนี้ชนกับงานที่คุณรับไว้แล้ว '
      'หรือมีเวลาพักระหว่างงานไม่ถึง 2 ชั่วโมง\n\n'
      'กรุณาเลือกงานอื่น โดยแต่ละงานต้องมีระยะห่างกันอย่างน้อย 2 ชั่วโมง',
      style: TextStyle(fontSize: 16),
    ),
  );
}

// ===================== dialog ที่เรียกใช้จริงหน้าหลักผู้ให้บริการ =====================

Future<void> showAccountPendingDialog(BuildContext context, String pid) {
  return _showRedDialogHompage(
    context: context,
    title: 'กรุณายืนยันเอกสาร',
    icon: Icons.description_outlined,
    content: const Text(
      'บัญชีของคุณยังไม่ได้รับการตรวจสอบ\n\n'
      'กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน '
      'เช่น รูปโปรไฟล์ เบอร์โทรศัพท์ และข้อมูลส่วนตัว '
      'รวมถึงส่งเอกสารที่จำเป็นให้ครบถ้วน\n\n'
      'จากนั้นรอผู้ดูแลระบบตรวจสอบบัญชี '
      'เมื่อผ่านการตรวจสอบแล้วจึงจะสามารถสมัครงานได้',
      style: TextStyle(fontSize: 16),
    ),
    buildActions: (dialogContext) => [
      Expanded(
        child: ElevatedButton(
          style: _confirmStyle(),
          onPressed: () {
            Navigator.push(
              dialogContext,
              MaterialPageRoute(builder: (context) => DocumentPage(pid: pid)),
            );
          },
          child: const Text('กรอกเอกสาร', style: TextStyle(fontSize: 16)),
        ),
      ),
    ],
  );
}

Future<void> showAccountApproveDialog(BuildContext context) {
  return _showRedDialogHompage(
    context: context,
    title: 'รอตรวจสอบเอกสาร',
    icon: Icons.hourglass_top_rounded,
    content: const Text(
      'คุณได้ส่งเอกสารสำหรับสมัครเป็นผู้ให้บริการเรียบร้อยแล้ว\n\n'
      'ขณะนี้เอกสารของคุณอยู่ระหว่างการตรวจสอบโดยผู้ดูแลระบบ '
      'จึงยังไม่สามารถสมัครงานได้ในขณะนี้\n\n'
      'กรุณารอผลการตรวจสอบ เมื่อเอกสารผ่านการอนุมัติแล้ว '
      'คุณจะสามารถกลับมาใช้งานและสมัครงานได้ตามปกติ',
      style: TextStyle(fontSize: 16),
    ),
    buildActions: (dialogContext) => [],
  );
}

Future<void> showAccountDisableDialog(BuildContext context) {
  return _showRedDialogHompage(
    context: context,
    title: 'บัญชีถูกระงับชั่วคราว',
    icon: Icons.block_rounded,
    content: const Text(
      'บัญชีของคุณถูกระงับการใช้งานชั่วคราว\n\n'
      'ขณะนี้คุณไม่สามารถสมัครงานได้ '
      'เนื่องจากบัญชีอยู่ระหว่างการตรวจสอบโดยผู้ดูแลระบบ\n\n'
      'กรุณารอการตรวจสอบและปลดระงับบัญชี '
      'จึงจะสามารถกลับมาใช้งานและสมัครงานได้ตามปกติ',
      style: TextStyle(fontSize: 16),
    ),
    buildActions: (dialogContext) => [],
  );
}

Future<void> showAccountRejectDialog(
  BuildContext context,
  String? rejectReason,
  String pid,
) {
  return _showRedDialogHompage(
    context: context,
    title: 'เอกสารไม่ผ่านการตรวจสอบ',
    icon: Icons.cancel_outlined,
    content: Text(
      'เอกสารของคุณไม่ผ่านการตรวจสอบ\n\n'
      'เหตุผล: ${rejectReason ?? "ไม่ระบุ"}\n\n'
      'กรุณาแก้ไขเอกสารและส่งใหม่อีกครั้ง',
      style: const TextStyle(fontSize: 16),
    ),
    buildActions: (dialogContext) => [
      Expanded(
        child: ElevatedButton(
          style: _confirmStyle(),
          onPressed: () {
            Navigator.push(
              dialogContext,
              MaterialPageRoute(builder: (context) => DocumentPage(pid: pid)),
            );
          },
          child: const Text('แก้ไขเอกสาร', style: TextStyle(fontSize: 16)),
        ),
      ),
    ],
  );
}
