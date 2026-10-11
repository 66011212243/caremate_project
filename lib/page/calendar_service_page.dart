import 'package:caremate_application/page/details_job_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarServicePage extends StatefulWidget {
  final String sid;

  const CalendarServicePage({super.key, required this.sid});

  @override
  State<CalendarServicePage> createState() => _CalendarServicePageState();
}

class _CalendarServicePageState extends State<CalendarServicePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<DateTime> _jobDates = [];
  List<Map<String, dynamic>> _jobs = [];

  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF800000);
  static const Color backgroundColor = Color(0xFFF7F7FB);

  @override
  void initState() {
    super.initState();
    loadJobDates();
  }

  @override
  Widget build(BuildContext context) {
    final selectedJobs = _selectedDay == null
        ? <Map<String, dynamic>>[]
        : _jobs.where((job) {
            final jobDate = parseJobDate(job['date']?.toString() ?? '');
            return jobDate != null && isSameDay(jobDate, _selectedDay!);
          }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : RefreshIndicator(
                color: primaryColor,
                onRefresh: loadJobDates,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // หัวข้อหน้า
                      const Text(
                        'ปฏิทินงานของฉัน',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29252B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ตรวจสอบวันและเวลาของงานที่มีผู้ให้บริการรับแล้ว',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // การ์ดปฏิทิน
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TableCalendar(
                              firstDay: DateTime.utc(2010, 10, 16),
                              lastDay: DateTime.utc(2030, 3, 14),
                              focusedDay: _focusedDay,
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                leftChevronIcon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: primaryColor,
                                  size: 28,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: primaryColor,
                                  size: 28,
                                ),
                                titleTextStyle: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF29252B),
                                ),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                weekendStyle: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              calendarStyle: const CalendarStyle(
                                outsideDaysVisible: false,
                                cellMargin: EdgeInsets.all(4),
                                defaultTextStyle: TextStyle(
                                  color: Color(0xFF39343A),
                                  fontSize: 14,
                                ),
                                weekendTextStyle: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: Color(0xFFFFE5E5),
                                  shape: BoxShape.circle,
                                ),
                                todayTextStyle: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                              },
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, day, focusedDay) {
                                  final hasJob = _jobDates.any(
                                    (date) => isSameDay(date, day),
                                  );

                                  if (!hasJob) return null;

                                  return Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE5E5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.25),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                                selectedBuilder: (context, day, focusedDay) {
                                  return Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                                todayBuilder: (context, day, focusedDay) {
                                  final hasJob = _jobDates.any(
                                    (date) => isSameDay(date, day),
                                  );

                                  return Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: hasJob
                                          ? const Color(0xFFFFE5E5)
                                          : const Color(0xFFF0EDF5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.45),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // คำอธิบายสี
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE5E5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'วันที่มีงาน',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'วันที่เลือก',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // หัวข้อรายการงาน
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'รายการงาน',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF29252B),
                              ),
                            ),
                          ),
                          if (_selectedDay != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE5E5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${selectedJobs.length} งาน',
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _selectedDay == null
                            ? 'เลือกวันที่บนปฏิทินเพื่อดูรายละเอียดงาน'
                            : 'วันที่ ${formatDate(_selectedDay!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // รายการงานของวันที่เลือก
                      if (_selectedDay == null)
                        _buildEmptyState(
                          icon: Icons.touch_app_rounded,
                          title: 'เลือกวันที่ที่ต้องการ',
                          subtitle: 'แตะวันที่บนปฏิทินเพื่อดูรายการงาน',
                        )
                      else if (selectedJobs.isEmpty)
                        _buildEmptyState(
                          icon: Icons.event_available_rounded,
                          title: 'ไม่มีงานในวันนี้',
                          subtitle: 'ลองเลือกวันที่อื่นที่มีงานในปฏิทิน',
                        )
                      else
                        ...selectedJobs.map(_buildJobCard),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final placeName = job['place_name']?.toString() ?? 'ไม่ระบุสถานที่';
    final date = job['date']?.toString() ?? '-';
    final startTime = job['start_time']?.toString() ?? '-';
    final endTime = job['end_time']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE7EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsJobService(jobId: job['job_id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ไอคอนสถานที่
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: primaryColor,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 13),

                // ข้อมูลงาน
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF29252B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 17,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              date,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 17,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$startTime - $endTime น.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE7EA)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: primaryColor.withOpacity(0.65)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF39343A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  DateTime? parseJobDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return null;

      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> loadJobDates() async {
    try {
      final jobSnapshot = await db
          .collection('jobs')
          .where('service_id', isEqualTo: widget.sid)
          .where('job_status', isGreaterThanOrEqualTo: 1)
          .where('job_status', isLessThanOrEqualTo: 8)
          .get();

      final List<DateTime> dates = [];
      final List<Map<String, dynamic>> jobs = [];

      for (final jobDoc in jobSnapshot.docs) {
        final jobData = jobDoc.data();
        final dateString = jobData['date']?.toString();

        if (dateString == null) continue;

        final jobDate = parseJobDate(dateString);
        if (jobDate == null) continue;

        dates.add(DateTime(jobDate.year, jobDate.month, jobDate.day));

        jobs.add({...jobData, 'job_id': jobDoc.id});
      }

      if (!mounted) return;

      setState(() {
        _jobDates = dates;
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('โหลดข้อมูลงานไม่สำเร็จ: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โหลดข้อมูลงานไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }
}
