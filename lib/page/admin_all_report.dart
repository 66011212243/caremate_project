import 'package:caremate_application/page/ReportDetailPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAllReport extends StatefulWidget {
  const AdminAllReport({super.key});

  @override
  State<AdminAllReport> createState() => _AdminAllReportState();
}

class _AdminAllReportState extends State<AdminAllReport> {
  var db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> reports = [];
  // รายงานทั้งหมด
  List<Map<String, dynamic>> get allReports => reports;

  // รอตรวจสอบ status = 0
  List<Map<String, dynamic>> get pendingReportList =>
      reports.where((r) => r['status_re'] == 0).toList();

  // ตรวจสอบแล้ว status = 1
  List<Map<String, dynamic>> get completedReportList =>
      reports.where((r) => r['status_re'] == 1).toList();
  int get totalReports => allReports.length;
  int get pendingReports => pendingReportList.length;
  int get completedReports => completedReportList.length;

  @override
  void initState() {
    super.initState();
    getAllReport();
  }

  Future<void> getAllReport() async {
    try {
      final reportsDoc = await db.collection('reports').get();

      final reportList = await Future.wait(
        reportsDoc.docs.map((reportDoc) async {
          final reportData = reportDoc.data();
          final reportedId = reportData['reported_provider_id'];

          String reporterName = 'ไม่พบข้อมูลผู้ใช้';
          String reporterEmail = '';
          String? providerProfile;

          if (reportedId != null) {
            print(reportedId);
            // 1. หา Provider ด้วย reporter_id
            final providerDoc = await db
                .collection('provider')
                .doc(reportedId.toString())
                .get();

            if (providerDoc.exists) {
              final providerData = providerDoc.data()!;
              final providerUid = providerData['provider_uid'];
              providerProfile = providerData['profile']?.toString();

              if (providerUid != null) {
                // 2. หา User ด้วย provider_uid
                final userDoc = await db
                    .collection('users')
                    .doc(providerUid.toString())
                    .get();

                if (userDoc.exists) {
                  final userData = userDoc.data()!;

                  reporterName =
                      userData['realname']?.toString() ?? 'ไม่ระบุชื่อ';

                  reporterEmail = userData['email']?.toString() ?? '';
                }
              }
            }
          }

          // 3. รวมข้อมูลรายงานกับข้อมูลผู้ใช้
          return {
            ...reportData,
            'report_id': reportDoc.id,
            'profile': providerProfile,
            'reporter_name': reporterName,
            'reporter_email': reporterEmail,
          };
        }),
      );

      if (!mounted) return;

      setState(() {
        reports = reportList;
      });
    } catch (e) {
      debugPrint('Error fetching reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ DefaultTabController หุ้มตรงนี้
    return DefaultTabController(
      length: 3, // กำหนดจำนวน Tab ให้ตรงกับที่มี
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFD32F2F),
          title: const Text(
            'รายงานผู้ให้บริการทั้งหมด',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // 2. สรุปสถิติภาพรวม (Summary Badges)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'รายงานทั้งหมด',
                      count: '$totalReports',
                      color: Colors.blue[700]!,
                      bgColor: Colors.blue[50]!,
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'รอตรวจสอบ',
                      count: '$pendingReports',
                      color: Colors.orange[800]!,
                      bgColor: Colors.orange[50]!,
                      icon: Icons.pending_actions,
                    ),
                  ),
                ],
              ),
            ),

            // 3. แท็บกรองสถานะ (Status Tabs)
            Container(
              color: Colors.white,
              child: TabBar(
                // ตัด controller: _tabController ออก
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                labelColor: const Color(0xFFD32F2F),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFD32F2F),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'ทั้งหมด ($totalReports)'),
                  Tab(text: 'รอตรวจสอบ ($pendingReports)'),
                  Tab(text: 'ตรวจสอบแล้ว ($completedReports)'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 4. รายการการ์ดรายงาน (Report Cards List)
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: รายงานทั้งหมด
                  buildReportList(allReports),

                  // Tab 2: รอตรวจสอบ (status_re = 0)
                  buildReportList(pendingReportList),

                  // Tab 3: ตรวจสอบแล้ว (status_re = 1)
                  buildReportList(completedReportList),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReportList(List<Map<String, dynamic>> reportList) {
    return RefreshIndicator(
      onRefresh: getAllReport,
      child: reportList.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(
                  height: 200,
                  child: Center(child: Text('ไม่มีรายการรายงาน')),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: reportList.length,
              itemBuilder: (context, index) {
                final report = reportList[index];
                final isPending = report['status_re'] == 0;

                return _buildReportCard(
                  reportId: report['report_id'],
                  name: report['reporter_name']?.toString() ?? 'ไม่ระบุชื่อ',
                  email: report['reporter_email']?.toString() ?? '',
                  statusText: isPending ? 'รอตรวจสอบ' : 'ตรวจสอบแล้ว',
                  statusColor: isPending
                      ? Colors.orange[800]!
                      : Colors.green[800]!,
                  statusBgColor: isPending
                      ? Colors.orange[50]!
                      : Colors.green[50]!,
                  imageUrl: report['profile'],
                );
              },
            ),
    );
  }

  // Widget การ์ดสถิติ
  Widget _buildStatCard({
    required String title,
    required String count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 20,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget การ์ดแสดงรายการผู้ถูกรายงาน
  Widget _buildReportCard({
    required String reportId,
    required String name,
    required String email,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
    String? imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailPage(reportsId: reportId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: imageUrl != null
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
