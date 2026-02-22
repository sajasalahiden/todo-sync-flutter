import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/task_list_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blushPink = Color(0xFFE56B8C);
    const softRose = Color(0xFFF4A7B9);
    const warmSkin = Color(0xFFFFF3EC);

    final colorScheme = ColorScheme.light(
      primary: blushPink,
      secondary: softRose,
      surface: warmSkin,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do Sync',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: StreamBuilder(
        stream: AuthService.instance.authChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return const TaskListScreen();
        },
      ),
    );
  }
}
