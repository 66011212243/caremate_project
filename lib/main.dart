import 'package:caremate_application/page/Bank.dart';
import 'package:caremate_application/page/Changepassword.dart';
import 'package:caremate_application/page/Report.dart';
import 'package:caremate_application/page/Review_history_service.dart';
import 'package:caremate_application/page/Review_history_provider.dart';
import 'package:caremate_application/page/break_status_job.dart';
import 'package:caremate_application/page/document.dart';
import 'package:caremate_application/page/edit_Bank.dart';
import 'package:caremate_application/page/edit_profile_provider.dart';
import 'package:caremate_application/page/edit_profile_service.dart';
import 'package:caremate_application/page/homepage_admin.dart';
import 'package:caremate_application/page/landing_page.dart';
import 'package:caremate_application/page/address_service_page.dart';
import 'package:caremate_application/page/Bank.dart';
import 'package:caremate_application/page/Changepassword.dart';
import 'package:caremate_application/page/break_status_job.dart';
import 'package:caremate_application/page/calendar_page.dart';
import 'package:caremate_application/page/details_job.dart';
import 'package:caremate_application/page/details_job_service.dart';
import 'package:caremate_application/page/history_job_provider.dart';
import 'package:caremate_application/page/history_job_service.dart';
import 'package:caremate_application/page/login.dart';
import 'package:caremate_application/page/myJob_povider.dart';
import 'package:caremate_application/page/position_provider.dart';
import 'package:caremate_application/page/register_provider.dart';
import 'package:caremate_application/page/registration_admin.dart';
import 'package:caremate_application/page/review.dart';
import 'package:caremate_application/page/setting_admin.dart';
import 'package:caremate_application/page/status_job.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/map_page.dart';
import 'package:caremate_application/page/Setting_Provider.dart';
import 'package:caremate_application/page/Changepassword.dart';
import 'package:flutter/material.dart';
import 'package:caremate_application/page/ReportDetailPage.dart';
import 'package:caremate_application/page/Review_history_provider.dart';
import 'package:caremate_application/page/approve_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginPage(),
    );
  }
}
