import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/geocoding_service.dart';

class SearchCitySheet extends StatefulWidget {
  final Function(String, LatLng) onCitySelected;

  const SearchCitySheet({super.key, required this.onCitySelected});

  @override
  State<SearchCitySheet> createState() => _SearchCitySheetState();
}

class _SearchCitySheetState extends State<SearchCitySheet> {
  final GeocodingService _geocodingService = GeocodingService();
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
        return;
      }

      setState(() => _isLoading = true);
      final results = await _geocodingService.searchAddresses(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Куда едем?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              hintText: 'Поиск улицы, адреса...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blueAccent,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          if (_results.isEmpty && !_isLoading) ...[
            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.home, 'Домой', () {
                  widget.onCitySelected('Дом', const LatLng(42.8722, 71.3789));
                  Navigator.pop(context);
                }),
                _buildQuickAction(Icons.work, 'На работу', () {
                  widget.onCitySelected(
                    'Работа',
                    const LatLng(42.8967, 71.3982),
                  );
                  Navigator.pop(context);
                }),
                _buildQuickAction(Icons.star, 'Избранное', () {}),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Популярные места',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Expanded(
            child: _results.isEmpty && !_isLoading
                ? _buildRecentList()
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.place,
                          color: Colors.blueAccent,
                        ),
                        title: Text(
                          result.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          widget.onCitySelected(
                            result.name,
                            result.coordinates,
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2C2C2C),
            child: Icon(icon, color: Colors.blueAccent),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentList() {
    final List<Map<String, dynamic>> favorites = [
      {'name': 'Төле би көшесі, 10', 'coords': const LatLng(42.8711, 71.3702)},
      {'name': 'Абай даңғылы, 150', 'coords': const LatLng(42.8805, 71.3850)},
    ];

    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final fav = favorites[index];
        return ListTile(
          leading: const Icon(Icons.history, color: Colors.grey),
          title: Text(
            fav['name'],
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          onTap: () {
            widget.onCitySelected(fav['name'], fav['coords']);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
            'Тараз қаласы бойынша іздеу',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
