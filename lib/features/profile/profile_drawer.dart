import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'profile_screen.dart';
import '../driver/become_driver_screen.dart';
import '../settings/settings_screen.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  String _name = 'Пользователь';
  String _phone = '';
  bool _isDriver = false;
  String _carInfo = '';

  @override
  void initState() {
    super.initState();
    _loadCachedProfile(); // Load cached data immediately
    _loadProfile(); // Then fetch fresh data
  }

  Future<void> _loadCachedProfile() async {
    final name = await AuthService().getCachedName();
    final phone = await AuthService().getCachedPhone();
    if (mounted) {
      setState(() {
        _name = name;
        _phone = phone;
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService().getUserProfile();
    if (mounted && profile != null) {
      setState(() {
        final firstName = profile['firstName'] ?? '';
        final lastName = profile['lastName'] ?? '';
        _name = '$firstName $lastName'.trim();
        if (_name.isEmpty) _name = 'Пользователь';
        _phone = profile['phoneNumber'] ?? '';

        // Check if user is a driver
        final driver = profile['driver'];
        if (driver != null) {
          _isDriver = true;
          final carModel = driver['carModel'] ?? '';
          final carNumber = driver['carNumber'] ?? '';
          _carInfo = '$carModel • $carNumber';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2C),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phone,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      if (_isDriver) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_taxi,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _carInfo,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Профиль',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'История поездок',
                  onTap: () {
                    // Navigate to History
                  },
                ),
                if (!_isDriver)
                  _buildDrawerItem(
                    context,
                    icon: Icons.local_taxi,
                    title: 'Стать водителем',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BecomeDriverScreen(),
                        ),
                      );
                    },
                  ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Настройки',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.support_agent,
                  title: 'Поддержка',
                  onTap: () {},
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Выйти', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}
