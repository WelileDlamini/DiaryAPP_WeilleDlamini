

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/pin_verify_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/access_code_service.dart';

class SecurityWrapper extends StatefulWidget {
  const SecurityWrapper({super.key});

  @override
  State<SecurityWrapper> createState() => _SecurityWrapperState();
}

class _SecurityWrapperState extends State<SecurityWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app returns from background or resumes
    if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
    }

    // When app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lockApp();
    }
  }

  Future<void> _checkLockStatus() async {
    try {
      final hasAccessCode = await AccessCodeService.hasAccessCode();
      final isEnabled = await AccessCodeService.isAccessCodeEnabled();
      final isLoggedIn = await AccessCodeService.isLoggedIn();

      if (mounted) {
        setState(() {
          // Only lock if PIN is configured, enabled, and not logged in
          _isLocked = hasAccessCode && isEnabled && !isLoggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocked = false; // In case of error, allow access
          _isLoading = false;
        });
      }
    }
  }

  void _lockApp() async {
    final hasAccessCode = await AccessCodeService.hasAccessCode();
    final isEnabled = await AccessCodeService.isAccessCodeEnabled();

    if (hasAccessCode && isEnabled) {
      // Clear login state when app goes to background
      await AccessCodeService.clearLoginState();

      if (mounted) {
        setState(() {
          _isLocked = true;
        });
      }
    }
  }

  Future<bool> _checkIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  void _onUnlocked() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLocked) {
      return PinVerifyScreen(
        canCancel: false,
        onVerificationSuccess: _onUnlocked,
      );
    }

    return FutureBuilder<bool>(
      future: _checkIsLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.data == true) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}