import 'package:caremate_application/page/details_job_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarServicePage extends StatefulWidget {
  String sid = "";
  CalendarServicePage({super.key, required this.sid});

  @override
  State<CalendarServicePage> createState() => _CalendarServicePageState();
}

class _CalendarServicePageState extends State<CalendarServicePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  var db = FirebaseFirestore.instance;

  List<DateTime> _jobDates = [];
  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();

    loadJobDates();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,

              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },

              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  bool hasJob = _jobDates.any(
                    (jobDate) => isSameDay(jobDate, day),
                  );

                  if (hasJob) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
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
                  }

                  return null;
                },
              ),
            ),

            if (_selectedDay != null)
              ..._jobs
                  .where((job) {
                    DateTime jobDate = parseJobDate(job['date']);

                    return isSameDay(jobDate, _selectedDay!);
                  })
                  .map((job) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailsJobService(jobId: job['job_id']),
                            ),
                          );
                        },
                        child: Container(
                          height: 90,
                          width: 380,
                          margin: const EdgeInsets.only(
                            top: 10,
                            left: 10,
                            right: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            border: Border.all(
                              color: const Color.fromARGB(255, 114, 8, 0),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.9),
                                blurRadius: 5,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 30, top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job['place_name'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month),
                                    const SizedBox(width: 5),

                                    Text(
                                      job['date'],
                                      style: const TextStyle(fontSize: 16),
                                    ),

                                    const SizedBox(width: 40),

                                    const Icon(Icons.access_time),
                                    const SizedBox(width: 5),

                                    Text(
                                      job['start_time'],
                                      style: const TextStyle(fontSize: 16),
                                    ),

                                    const Text(
                                      " - ",
                                      style: TextStyle(fontSize: 16),
                                    ),

                                    Text(
                                      job['end_time'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
          ],
        ),
      ),
    );
  }

  DateTime parseJobDate(String date) {
    List<String> parts = date.split('/');

    return DateTime(
      int.parse(parts[2]), // ปี
      int.parse(parts[1]), // เดือน
      int.parse(parts[0]), // วัน
    );
  }

  Future<void> loadJobDates() async {
    // ดึงเฉพาะงานของผู้รับบริการ
    // และเป็นงานที่มีผู้ให้บริการรับงานแล้ว
    var jobSnapshot = await db
        .collection('jobs')
        .where('service_id', isEqualTo: widget.sid)
        .where('job_status', isEqualTo: 1)
        .get();

    List<DateTime> dates = [];
    List<Map<String, dynamic>> jobs = [];

    for (var jobDoc in jobSnapshot.docs) {
      var jobData = jobDoc.data();

      String? dateString = jobData['date'];

      if (dateString != null) {
        DateTime jobDate = parseJobDate(dateString);

        dates.add(DateTime(jobDate.year, jobDate.month, jobDate.day));

        jobs.add({...jobData, 'job_id': jobDoc.id});
      }
    }

    setState(() {
      _jobDates = dates;
      _jobs = jobs;
    });
  }
}
