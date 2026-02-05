import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geolocator/geolocator.dart';
import '../profile/profile_drawer.dart';
import 'trip_details_sheet.dart';
import 'search_city_sheet.dart';
import '../../core/services/routing_service.dart';
import '../../core/services/geocoding_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Almaty coordinates as default
  LatLng _center = const LatLng(43.238949, 76.889709);
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  String? _destinationAddress;

  String _pickupAddress = 'Определение адреса...';
  LatLng? _pickupLocation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();
  final GeocodingService _geocodingService = GeocodingService();

  Timer? _mapMoveDebounce;

  void _onMapMoved(LatLng center) {
    if (_mapMoveDebounce?.isActive ?? false) _mapMoveDebounce!.cancel();
    _mapMoveDebounce = Timer(const Duration(milliseconds: 1000), () async {
      final address = await _geocodingService.reverseGeocode(center);
      if (mounted && address != null) {
        setState(() {
          _pickupAddress = address;
          _pickupLocation = center;
        });
        if (_destination != null) {
          _updateRoute(_destination!);
        }
      }
    });
  }

  List<Marker> _buildDriverMarkers() {
    // Simulated driver locations around Taraz center
    final List<LatLng> driverLocs = [
      LatLng(_center.latitude + 0.005, _center.longitude + 0.005),
      LatLng(_center.latitude - 0.003, _center.longitude + 0.008),
      LatLng(_center.latitude + 0.007, _center.longitude - 0.002),
    ];

    return driverLocs
        .map(
          (loc) => Marker(
            point: loc,
            width: 30,
            height: 30,
            child: Transform.rotate(
              angle: 0.5,
              child: const Icon(
                Icons.local_taxi,
                color: Colors.yellow,
                size: 24,
              ),
            ),
          ),
        )
        .toList();
  }

  Future<void> _updateRoute(LatLng destination) async {
    final start = _pickupLocation ?? _center;
    final route = await _routingService.getRoute(start, destination);
    if (mounted) {
      setState(() {
        _destination = destination;
        _routePoints = route;
      });

      if (_routePoints.isNotEmpty) {
        _fitRoute();
      } else {
        _mapController.move(destination, 15.0);
      }
    }
  }

  void _fitRoute() {
    if (_routePoints.isEmpty) return;

    final start = _pickupLocation ?? _center;
    final points = [start, ..._routePoints];
    if (_destination != null) points.add(_destination!);

    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
    );
  }

  @override
  void dispose() {
    _mapMoveDebounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      if (_pickupLocation == null) {
        _pickupLocation = _center;
        _pickupAddress = 'Ваше текущее местоположение';
      }
    });
    _mapController.move(_center, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ProfileDrawer(),
      body: Stack(
        children: [
          // MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
              onPositionChanged: (MapPosition position, bool hasGesture) {
                if (hasGesture && _routePoints.isEmpty) {
                  // If user is manually moving map (and not in a trip route)
                  _onMapMoved(position.center!);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.flux.taxi.app',
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 5,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Simulated Drivers
                  ..._buildDriverMarkers(),

                  // Only show destination marker if it exists
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // GPS BUTTON (Bottom Right - above the sheet)
          Positioned(
            right: 20,
            bottom: 300,
            child: FadeInRight(
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _determinePosition,
                child: const Icon(Icons.my_location, color: Colors.blueAccent),
              ),
            ),
          ),

          // FIXED CENTRAL PIN (Yandex Style)
          if (_routePoints.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 40), // Offset for pin tip
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Эта точка',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      color: Colors.blueAccent,
                      size: 45,
                    ),
                  ],
                ),
              ),
            ),

          // DRAWER BUTTON (Top Left)
          Positioned(
            top: 50,
            left: 20,
            child: FadeInDown(
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.menu, color: Colors.black),
                ),
              ),
            ),
          ),

          // BOTTOM SHEET LAYER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location Indicator
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => SearchCitySheet(
                            onCitySelected: (name, coordinates) {
                              setState(() {
                                _pickupAddress = name;
                                _pickupLocation = coordinates;
                              });
                              if (_destination != null) {
                                _updateRoute(_destination!);
                              } else {
                                _mapController.move(coordinates, 15.0);
                              }
                            },
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.my_location,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Откуда?',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _pickupAddress,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Button / UI if destination is set
                    if (_destination != null) ...[
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payments,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Наличные',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '~ 850 ₸',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => TripDetailsSheet(
                                initialFrom: _pickupAddress,
                                initialTo: _destinationAddress,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Вызвать такси',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Where to? Input
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          title: Text(
                            'Куда едем?',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => SearchCitySheet(
                                onCitySelected: (name, coordinates) {
                                  setState(() {
                                    _destinationAddress = name;
                                  });
                                  _updateRoute(coordinates);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
