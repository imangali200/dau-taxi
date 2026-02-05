import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../rating/rating_dialog.dart';
import '../home/search_city_sheet.dart';

enum TripState { booking, searching, arriving, inTrip }

class TripDetailsSheet extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;

  const TripDetailsSheet({super.key, this.initialFrom, this.initialTo});

  @override
  State<TripDetailsSheet> createState() => _TripDetailsSheetState();
}

class _TripDetailsSheetState extends State<TripDetailsSheet> {
  TripState _currentState = TripState.booking;
  final String _statusText = '';

  late String _fromLocation;
  late String _toLocation;

  @override
  void initState() {
    super.initState();
    _fromLocation = widget.initialFrom ?? 'Ваше местоположение';
    _toLocation = widget.initialTo ?? 'Улица Панфилова, 98';
  }

  // Driver Info
  final String _driverName = "Сакен";
  final String _carModel = "Toyota Camry 70";
  final String _plateNumber = "777 ABZ 02";

  void _startTripFlow() {
    setState(() {
      _currentState = TripState.searching;
    });

    // Simulate Finding Driver (3s)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentState = TripState.arriving;
        });
      }

      // Simulate Arrival (5s)
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _currentState = TripState.inTrip;
          });
        }

        // Simulate Grid/Finish (5s)
        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            Navigator.pop(context); // Close sheet
            showDialog(
              context: context,
              builder: (context) => const RatingDialog(),
            );
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Increased height for better visibility
    // If arriving/inTrip, we might need more space for driver info
    final double sheetHeight = _currentState == TripState.booking ? 400 : 450;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: sheetHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 24, bottom: 32, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Content based on state
          Expanded(child: _buildStateContent()),
        ],
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_currentState) {
      case TripState.booking:
        return _buildBookingView();
      case TripState.searching:
        return _buildSearchingView();
      case TripState.arriving:
        return _buildArrivingView();
      case TripState.inTrip:
        return _buildInTripView();
    }
  }

  Widget _buildBookingView() {
    return Column(
      children: [
        // Route Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildLocationRow(
                icon: Icons.my_location,
                iconColor: Colors.blueAccent,
                title: 'Откуда',
                value: _fromLocation,
                isLast: false,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => SearchCitySheet(
                      onCitySelected: (name, coordinates) {
                        setState(() {
                          _fromLocation = name;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildLocationRow(
                icon: Icons.location_on,
                iconColor: Colors.redAccent,
                title: 'Куда',
                value: _toLocation,
                isLast: true,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => SearchCitySheet(
                      onCitySelected: (name, coordinates) {
                        setState(() {
                          _toLocation = name;
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payment (Cash)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.money, color: Colors.green),
              const SizedBox(width: 12),
              const Text(
                'Наличными',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        const Spacer(),

        // Order Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startTripFlow,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Заказать такси',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blueAccent),
          const SizedBox(height: 24),
          Text(
            'Поиск водителя...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Это займет пару секунд',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivingView() {
    return Column(
      children: [
        Text(
          'Водитель в пути',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Прибудет через 3 мин',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),

        // Driver/Car Info
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // Car Icon/Image placeholder
              Container(
                width: 80,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plateNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _carModel,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Driver Profile
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            _driverName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text('4.9', style: TextStyle(color: Colors.grey[400])),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircleBtn(Icons.message),
              const SizedBox(width: 12),
              _buildCircleBtn(Icons.call),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInTripView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            child: const Icon(Icons.speed, color: Colors.green, size: 60),
          ),
          const SizedBox(height: 24),
          Text(
            'В пути',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Прибытие через 15 мин',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isLast,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (!isLast)
                Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      4,
                      (index) => Container(
                        width: 2,
                        height: 2,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (!isLast) const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
