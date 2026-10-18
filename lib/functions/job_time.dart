import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// รวม date ("15/10/2026") + start_time ("22:57") เป็น DateTime
DateTime? parseJobStart(Map<String, dynamic> job) {
  try {
    final dateStr = job['date'] as String;
    final timeStr = job['start_time'] as String;

    final d = dateStr.split('/');
    final t = timeStr.split(':');

    return DateTime(
      int.parse(d[2]),
      int.parse(d[1]),
      int.parse(d[0]),
      int.parse(t[0]),
      int.parse(t[1]),
    );
  } catch (e) {
    debugPrint('อ่านเวลาเริ่มงานไม่ได้: $e');
    return null;
  }
}

/// ใช้ start_at (Timestamp) ก่อน ถ้าไม่มี (งานเก่า) ค่อย fallback
DateTime? jobStartTime(Map<String, dynamic> job) {
  final at = job['start_at'];
  if (at is Timestamp) return at.toDate();
  return parseJobStart(job);
}