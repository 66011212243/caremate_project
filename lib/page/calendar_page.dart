import 'package:caremate_application/page/details_job.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  String pid = "";
  CalendarPage({super.key, required this.pid});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _selectedIndex = 1;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<DateTime> _jobDates = [];
  List<Map<String, dynamic>> _jobs = [];

  var db = FirebaseFirestore.instance;

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

              // eventLoader: (day) {
              //   return _jobDates
              //       .where((jobDate) => isSameDay(jobDate, day))
              //       .toList();
              // },
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
                              builder: (context) => DetailsJob(
                                jobId: job['job_id'],
                                pid: widget.pid,
                              ),
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

                                // วันที่ + เวลา
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

                                const SizedBox(height: 10),
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
    var applicationSnapshot = await db
        .collection('all_drivers')
        .where('provider_id', isEqualTo: widget.pid)
        .get();

    List<DateTime> dates = [];
    List<Map<String, dynamic>> jobs = [];

    for (var doc in applicationSnapshot.docs) {
      var applicationData = doc.data();

      // ใช้ status_drivers จาก all_drivers
      int? statusDrivers = (applicationData['status_drivers'] as num?)?.toInt();

      // เอาเฉพาะคนที่ได้รับงานแล้ว
      if (statusDrivers != 1) {
        continue;
      }

      String? jobId = applicationData['job_id'];

      if (jobId == null) continue;

      var jobDoc = await db.collection('jobs').doc(jobId).get();

      if (!jobDoc.exists) continue;

      var jobData = jobDoc.data();

      if (jobData == null) continue;

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
