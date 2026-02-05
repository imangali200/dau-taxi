import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/services/auth_service.dart';

class BecomeDriverScreen extends StatefulWidget {
  const BecomeDriverScreen({super.key});

  @override
  State<BecomeDriverScreen> createState() => _BecomeDriverScreenState();
}

class _BecomeDriverScreenState extends State<BecomeDriverScreen> {
  final _carModelController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _carColorController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitDriverProfile() async {
    if (_carModelController.text.isEmpty ||
        _carNumberController.text.isEmpty ||
        _carColorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все поля'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Step 1: Update driver profile
    final profileSuccess = await AuthService().updateDriverProfile(
      carModel: _carModelController.text,
      carNumber: _carNumberController.text,
      carColor: _carColorController.text,
    );

    if (!profileSuccess) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка сохранения данных'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 2: Switch role to driver
    final roleSuccess = await AuthService().switchToDriver();

    if (mounted) {
      setState(() => _isLoading = false);
      if (roleSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы стали водителем! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка смены роли'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Стать водителем',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.local_taxi,
                        size: 64,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Заполните данные автомобиля',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'После проверки вы сможете принимать заказы',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Car Model
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: TextField(
                controller: _carModelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Модель автомобиля *',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Toyota Camry 70',
                  hintStyle: TextStyle(color: Colors.white24),
                  prefixIcon: Icon(Icons.directions_car, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Car Number
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: TextField(
                controller: _carNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Гос. номер *',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: '777 ABZ 02',
                  hintStyle: TextStyle(color: Colors.white24),
                  prefixIcon: Icon(Icons.app_registration, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Car Color
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: TextField(
                controller: _carColorController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Цвет *',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: 'Белый',
                  hintStyle: TextStyle(color: Colors.white24),
                  prefixIcon: Icon(Icons.palette, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDriverProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Стать водителем',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
