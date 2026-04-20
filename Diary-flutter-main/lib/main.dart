import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_wrapper.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';

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
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(() {
      setState(() {});
    });
    _initialScreen = _getInitialScreen();
  }

  void toggleTheme() {
    _themeProvider.toggleTheme();
  }

  bool get isDarkMode => _themeProvider.isDarkMode;

  // Determine which screen to show based on login status
  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (isLoggedIn) {
      return const SecurityWrapper();
    } else {
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDiary',
      debugShowCheckedModeBanner: false,
      theme: _themeProvider.currentTheme,
      themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: FutureBuilder<Widget>(
        future: _initialScreen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Error loading app. Please restart.'),
              ),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }
}