import 'package:flutter/material.dart';
import 'package:namer_app/records.dart';

import 'streamApp.dart';
import 'homePage.dart';
import 'recordingsApp.dart';
import 'fileVideoApp.dart';
import 'starting_select_page.dart';
import 'apps_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 90, 6, 201),
        ),
      ),
      initialRoute: AppsRoutes.startingScreen,
      routes: {
        // '/recordings': (context) => RecordingsApp(),
        AppsRoutes.projectSelect: (context) => StartingSelecetPage(),

        // Video player with RecordData in arguments
        AppsRoutes.fileVideoPlayer: (context) => FileVideoApp(
          record: ModalRoute.of(context)!.settings.arguments as RecordData,
        ),
        // '/streamVideoPlayer': (context) => StreamPlayerApp(),
      },
    );
  }
}
