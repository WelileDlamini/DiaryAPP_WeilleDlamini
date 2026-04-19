import 'package:flutter/material.dart';
import 'security_wrapper.dart';  // This imports the correct StatefulWidget
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences database
  // No explicit initialization needed

  // Initialize notification service
  await NotificationService().initialize();

  // Request notification permissions
  await NotificationService().requestPermissions();

  runApp(MyDiaryApp());
}

class MyDiaryApp extends StatefulWidget {
  static final GlobalKey<_MyDiaryAppState> appKey = GlobalKey<_MyDiaryAppState>();

  MyDiaryApp() : super(key: appKey);

  @override
  State<MyDiaryApp> createState() => _MyDiaryAppState();

  static _MyDiaryAppState? of(BuildContext context) {
    return appKey.currentState;
  }
}

class _MyDiaryAppState extends State<MyDiaryApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(() {
      setState(() {});
    });
  }

  void toggleTheme() {
    _themeProvider.toggleTheme();
  }

  bool get isDarkMode => _themeProvider.isDarkMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiary',
      debugShowCheckedModeBanner: false,
      theme: _themeProvider.currentTheme,
      themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SecurityWrapper(),  // Now this uses the correct Widget from security_wrapper.dart
    );
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }
}

