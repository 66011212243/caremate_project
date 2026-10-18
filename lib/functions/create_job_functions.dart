import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> checkJobTimeConflict({
  required FirebaseFirestore db,
  required String serviceId,
  required String date,
  required String startTime,
  required String endTime,
  String? excludeJobId,
}) async {
  try {
    final result = await db
        .collection('jobs')
        .where('service_id', isEqualTo: serviceId)
        .where('date', isEqualTo: date)
        .get();

    final newStart = timeToMinutes(startTime);
    final newEnd = timeToMinutes(endTime);

    for (final doc in result.docs) {
      // 1. ข้ามงานที่กำลังแก้ไข
      if (excludeJobId != null && doc.id == excludeJobId) {
        continue;
      }

      final data = doc.data();

      // 2. ข้ามงานที่เสร็จแล้วหรือยกเลิกแล้ว
      final status = data['job_status'];
      if (status == 9 || status == 10) {
        continue;
      }

      final oldStart = timeToMinutes(data['start_time'].toString());
      final oldEnd = timeToMinutes(data['end_time'].toString());

      const gap = 120;

      // งานใหม่อยู่หลังงานเดิม
      if (newStart >= oldEnd) {
        if (newStart - oldEnd < gap) {
          return false;
        }
      }
      // งานใหม่อยู่ก่อนงานเดิม
      else if (newEnd <= oldStart) {
        if (oldStart - newEnd < gap) {
          return false;
        }
      }
      // เวลาทับซ้อนกัน
      else {
        return false;
      }
    }

    return true;
  } catch (e, stackTrace) {
    print('checkJobTimeConflict error: $e');
    print(stackTrace);
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
