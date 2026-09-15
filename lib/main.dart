import 'package:caremate_application/page/break_status_job.dart';
import 'package:caremate_application/page/login.dart';
import 'package:caremate_application/page/myJob_povider.dart';
import 'package:caremate_application/page/position_provider.dart';
import 'package:caremate_application/page/register_provider.dart';
import 'package:caremate_application/page/status_job.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:caremate_application/page/homepage_provider.dart';
import 'package:caremate_application/page/homepage_service.dart';
import 'package:caremate_application/page/map_page.dart';
import 'package:flutter/material.dart';
import 'package:caremate_application/page/review.dart';

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
        // This is the theme of your application.
        //
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ReviewPage(),
    );
  }
}
