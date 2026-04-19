

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../components/bottom_nav.dart';
import 'notes_screen.dart';
import 'statistics_screen.dart';
import 'reminders_screen.dart';
import 'pin_setup_screen.dart';
import 'pin_verify_screen.dart';
import '../main.dart';
import '../services/database_service.dart';
import '../services/access_code_service.dart';
import '../services/media_service.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool hasAccessCode = false;
  bool accessCodeEnabled = false;
  Map<String, int> _stats = {'total': 0, 'favorites': 0, 'consecutive_days': 0};
  String _userName = 'User';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAccessCodeStatus();
    _loadUserName();
    _loadProfileImage();
  }

  Future<void> _loadAccessCodeStatus() async {
    final hasCode = await AccessCodeService.hasAccessCode();
    final isEnabled = await AccessCodeService.isAccessCodeEnabled();
    if (mounted) {
      setState(() {
        hasAccessCode = hasCode;
        accessCodeEnabled = isEnabled;
      });
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await DatabaseService.instance.getStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = {'total': 0, 'favorites': 0, 'consecutive_days': 0};
        });
      }
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');
    if (mounted && savedName != null) {
      setState(() {
        _userName = savedName;
      });
    }
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path');
    if (mounted && imagePath != null && await File(imagePath).exists()) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  Future<void> _saveProfileImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', imagePath);
    if (mounted) {
      setState(() {
        _profileImagePath = imagePath;
      });
    }
  }

  void _showChangeProfileImageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF7B2D8E)),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF7B2D8E)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              if (_profileImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final String? imagePath = await MediaService().takePhoto();
      if (imagePath != null) {
        await _saveProfileImage(imagePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final String? imagePath = await MediaService().pickImageFromGallery();
      if (imagePath != null) {
        await _saveProfileImage(imagePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      if (_profileImagePath != null) {
        await MediaService().deleteImage(_profileImagePath!);

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('profile_image_path');

        if (mounted) {
          setState(() {
            _profileImagePath = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditUserNameDialog() {
    final TextEditingController controller =
        TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Username'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  _saveUserName(newName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Username updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _handleAccessCodeTap() async {
    if (!hasAccessCode) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PinSetupScreen(),
        ),
      );

      if (result == true) {
        _loadAccessCodeStatus();
      }
    } else {
      _showAccessCodeOptions();
    }
  }

  void _showAccessCodeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  accessCodeEnabled ? Icons.lock_open : Icons.lock,
                  color: const Color(0xFF7B2D8E),
                ),
                title:
                    Text(accessCodeEnabled ? 'Disable PIN' : 'Enable PIN'),
                subtitle: Text(accessCodeEnabled
                    ? 'PIN will no longer protect the app'
                    : 'PIN will protect the app'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleAccessCode();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF7B2D8E)),
                title: const Text('Change PIN'),
                subtitle: const Text('Set up a new access code'),
                onTap: () {
                  Navigator.pop(context);
                  _changeAccessCode();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove PIN'),
                subtitle:
                    const Text('Completely remove the access code'),
                onTap: () {
                  Navigator.pop(context);
                  _removeAccessCode();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleAccessCode() async {
    if (accessCodeEnabled) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              const PinVerifyScreen(canCancel: true),
        ),
      );

      if (result == true) {
        await AccessCodeService.setAccessCodeEnabled(false);
        _loadAccessCodeStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN disabled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      await AccessCodeService.setAccessCodeEnabled(true);
      _loadAccessCodeStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN enabled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _changeAccessCode() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinSetupScreen(isChanging: true),
      ),
    );

    if (result == true) {
      _loadAccessCodeStatus();
    }
  }

  Future<void> _removeAccessCode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Access Code'),
          content: const Text(
            'Are you sure you want to completely remove the access code? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final verified = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              const PinVerifyScreen(canCancel: true),
        ),
      );

      if (verified == true) {
        await AccessCodeService.removeAccessCode();
        _loadAccessCodeStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access code removed successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(Icons.person, color: const Color(0xFF7B2D8E)),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit, size: 28),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon')),
                );
              }),
          IconButton(
              icon: Icon(
                DiaryApp.appKey.currentState?.isDarkMode == true
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
                size: 28,
              ),
              onPressed: () {
                DiaryApp.appKey.currentState?.toggleTheme();
              }),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _showChangeProfileImageDialog,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[700]
                                    : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .shadowColor
                                    .withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _profileImagePath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_profileImagePath!),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Color(0xFF7B2D8E),
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Color(0xFF7B2D8E),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showChangeProfileImageDialog,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B2D8E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[700]!
                                      : Colors.white,
                                  width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showEditUserNameDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotesScreen(),
                            ),
                          );
                        },
                        child: _ProfileStat('${_stats['total']}', 'Entries'),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatisticsScreen(),
                            ),
                          );
                        },
                        child: _ProfileStat(
                            '${_stats['consecutive_days']}', 'Streak'),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotesScreen(initialFilter: 'Favorites'),
                            ),
                          );
                        },
                        child:
                            _ProfileStat('${_stats['favorites']}', 'Favorites'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Options
            _MenuSection(
              title: 'My Diary',
              items: [
                _MenuItem(
                  icon: Icons.book_outlined,
                  title: 'My Entries',
                  subtitle: 'View all diary entries',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotesScreen()),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.favorite_border,
                  title: 'Favorites',
                  subtitle: 'Entries marked as favorites',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const NotesScreen(initialFilter: 'Favorites')),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.analytics_outlined,
                  title: 'Statistics',
                  subtitle: 'Activity analysis',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StatisticsScreen()),
                    );
                  },
                ),
              ],
            ),

            _MenuSection(
              title: 'Appearance',
              items: [
                _MenuItem(
                  icon: Icons.nightlight_round,
                  title: 'Dark Mode',
                  subtitle: 'Enable dark theme',
                  onTap: () {
                    DiaryApp.appKey.currentState?.toggleTheme();
                  },
                  hasSwitch: true,
                  switchValue:
                      DiaryApp.appKey.currentState?.isDarkMode ?? false,
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Reminders',
                  subtitle: 'Configure notifications',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RemindersScreen()),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.notification_add_outlined,
                  title: 'Test Notification',
                  subtitle: 'Send a test notification',
                  onTap: () async {
                    try {
                      await NotificationService().testNotification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification sent ✓'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending notification: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            _MenuSection(
              title: 'Privacy & Security',
              items: [
                _MenuItem(
                  icon: Icons.lock_outline,
                  title: 'Access Code',
                  subtitle: hasAccessCode
                      ? (accessCodeEnabled
                          ? 'PIN enabled'
                          : 'PIN configured but disabled')
                      : 'Protect app with PIN',
                  onTap: () => _handleAccessCodeTap(),
                  hasSwitch: hasAccessCode,
                  switchValue: accessCodeEnabled,
                ),
                _MenuItem(
                  icon: Icons.shield_outlined,
                  title: 'Privacy',
                  subtitle: 'Configure privacy options',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Coming soon: Privacy settings')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                            'Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();

                              await AccessCodeService.clearLoginState();

                              final hasActivePin = await AccessCodeService
                                      .isAccessCodeEnabled() &&
                                  await AccessCodeService.hasAccessCode();

                              if (hasActivePin) {
                                SystemNavigator.pop();
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Signed out.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}


class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7B2D8E),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}


class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}


class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool hasSwitch;
  final bool switchValue;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.hasSwitch = false,
    this.switchValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF7B2D8E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF7B2D8E),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              onChanged: (value) => onTap(),
              activeThumbColor: const Color(0xFF7B2D8E),
            )
          : Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
      onTap: hasSwitch ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}