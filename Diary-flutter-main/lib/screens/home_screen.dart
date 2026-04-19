// ==================================================
// MyDiary - Home Screen
// Developer: Welile Dlamini
// Course: Mobile App Final Project (CS441)
// Date: April 2026
// ==================================================

import 'package:flutter/material.dart';
import '../components/weather_card.dart';
import '../components/bottom_nav.dart';
import '../main.dart';
import '../services/database_service.dart';
import 'notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, int> _stats = {'total': 0, 'favorites': 0, 'consecutive_days': 0};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  // Load diary statistics from database
  Future<void> _loadStatistics() async {
    try {
      final stats = await DatabaseService.instance.getStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = {'total': 0, 'favorites': 0, 'consecutive_days': 0};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(Icons.phone_iphone, color: const Color(0xFF7B2D8E)), // Purple
        ),
        title: const Text(
          'My Diary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              MyDiaryApp.appKey.currentState?.isDarkMode == true
                  ? Icons.wb_sunny
                  : Icons.nightlight_round,
              size: 28,
            ),
            onPressed: () {
              MyDiaryApp.appKey.currentState?.toggleTheme();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Weather widget
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: WeatherCard(),
                  ),
                  const SizedBox(height: 8),

                  // Quick statistics cards
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                          child: _QuickStat(
                            icon: Icons.book,
                            label: 'Entries',
                            count: '${_stats['total']}',
                            color: const Color(0xFF7B2D8E), // Purple
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotesScreen(
                                    initialFilter: 'Favorites'),
                              ),
                            );
                          },
                          child: _QuickStat(
                            icon: Icons.favorite,
                            label: 'Favorites',
                            count: '${_stats['favorites']}',
                            color: Colors.red[400]!,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotesScreen(
                                    initialFilter: 'Recent'),
                              ),
                            );
                          },
                          child: _QuickStat(
                            icon: Icons.local_fire_department,
                            label: 'Streak',
                            count: '${_stats['consecutive_days']}',
                            color: Colors.orange[400]!,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Welcome message - shown when no entries exist
                  if (_stats['total'] == 0)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 48, color: Color(0xFF7B2D8E)), // Purple
                              SizedBox(height: 16),
                              Text(
                                'Welcome to MyDiary!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create your first entry and start documenting your daily experiences.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 100), // Space for bottom navigation
                ],
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}

// ==================================================
// Quick Statistics Widget
// ==================================================
class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to view',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}