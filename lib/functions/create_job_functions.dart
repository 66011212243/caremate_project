import 'package:cloud_firestore/cloud_firestore.dart';


Future<bool> checkJobTimeConflict({
  required FirebaseFirestore db,
  required String serviceId,
  required String date,
  required String startTime,
  required String endTime,
}) async {
  try {
    // ดึงงานของ service คนนี้ในวันเดียวกัน
    final result = await db
        .collection('jobs')
        .where('service_id', isEqualTo: serviceId)
        .where('date', isEqualTo: date)
        .get();

    // ถ้าวันนี้ยังไม่มีงาน → สร้างได้
    if (result.docs.isEmpty) {
      return true;
    }

    // แปลงเวลาใหม่เป็นนาที
    final newStart = timeToMinutes(startTime);
    final newEnd = timeToMinutes(endTime);

    // ตรวจทุกงานในวันนั้น
    for (final doc in result.docs) {
      final data = doc.data();

      final oldStart = timeToMinutes(data['start_time'].toString());

      final oldEnd = timeToMinutes(data['end_time'].toString());

      // ต้องห่างอย่างน้อย 2 ชั่วโมง = 120 นาที
      const gap = 120;

      // กรณีงานใหม่อยู่หลังงานเดิม
      if (newStart >= oldEnd) {
        final difference = newStart - oldEnd;

        if (difference < gap) {
          return false;
        }
      }

      // กรณีงานใหม่อยู่ก่อนงานเดิม
      if (newEnd <= oldStart) {
        final difference = oldStart - newEnd;

        if (difference < gap) {
          return false;
        }
      }

      // กรณีเวลาทับกัน
      if (newStart < oldEnd && newEnd > oldStart) {
        return false;
      }
    }

    return true;
  } catch (e) {
    print("checkJobTimeConflict error: $e");

    // ถ้าเช็คไม่ได้ ไม่ควรให้สร้างงาน
    return false;
  }
}

// แปลงเวลา เช่น 08:30 → 510 นาที
int timeToMinutes(String time) {
  final parts = time.split(':');

  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  return (hour * 60) + minute;
}

class PreviousPlace {
  final String name;
  final double latitude;
  final double longitude;

  PreviousPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

Future<List<PreviousPlace>> loadPreviousPlaces({
  required FirebaseFirestore db,
  required String serviceId,
}) async {
  final result = await db
      .collection('jobs')
      .where('service_id', isEqualTo: serviceId)
      .get();

  final Map<String, PreviousPlace> uniquePlaces = {};

  for (final doc in result.docs) {
    final data = doc.data();

    final name = data['place_name']?.toString();

    if (name == null || name.trim().isEmpty) {
      continue;
    }

    final latitude = data['latitude'];
    final longitude = data['longitude'];

    if (latitude == null || longitude == null) {
      continue;
    }

    uniquePlaces[name] = PreviousPlace(
      name: name,
      latitude: (latitude as num).toDouble(),
      longitude: (longitude as num).toDouble(),
    );
  }

  return uniquePlaces.values.toList();
}
