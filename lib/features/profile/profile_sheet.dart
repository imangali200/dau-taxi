import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FadeInUp(
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Алихан Смаилов',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          '+7 707 123 45 67',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildMenuItem(context, Icons.history, 'История поездок'),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildMenuItem(context, Icons.payment, 'Способы оплаты'),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildMenuItem(context, Icons.settings, 'Настройки'),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildMenuItem(context, Icons.support, 'Поддержка'),
                ),
                
                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: TextButton(
                    onPressed: () {
                      // Logout logic
                    },
                    child: const Text('Выйти', style: TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
