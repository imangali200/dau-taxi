import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SearchResult {
  final String name;
  final LatLng coordinates;

  SearchResult(this.name, this.coordinates);
}

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<SearchResult>> searchAddresses(String query) async {
    if (query.trim().length < 3) return [];

    try {
      // Clean query: remove special chars if stuck together
      String cleanQuery = query.replaceAll(RegExp(r'(\d+)'), r' $1').trim();

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$cleanQuery, Taraz',
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
        'countrycodes': 'kz',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FluxTaxiApp_Antigravity/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // If no results, try without "Taraz" suffix in 'q' but still with countrycodes
        if (data.isEmpty) {
          final fallbackUri = Uri.https(
            'nominatim.openstreetmap.org',
            '/search',
            {
              'q': cleanQuery,
              'format': 'json',
              'limit': '5',
              'countrycodes': 'kz',
            },
          );
          final fallbackResponse = await http.get(
            fallbackUri,
            headers: {'User-Agent': 'FluxTaxiApp_Antigravity/1.0'},
          );
          if (fallbackResponse.statusCode == 200) {
            final List<dynamic> fallbackData = json.decode(
              fallbackResponse.body,
            );
            return _parseData(fallbackData);
          }
        }

        return _parseData(data);
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return [];
  }

  Future<String?> reverseGeocode(LatLng location) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FluxTaxiApp_Antigravity/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String name = data['display_name'].toString();
        // Take first 3 parts for a cleaner address
        return name.split(',').take(3).join(',').trim();
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    return null;
  }

  List<SearchResult> _parseData(List<dynamic> data) {
    return data.map((item) {
      // Remove "Kazakhstan" and other redundant parts for cleaner UI
      String name = item['display_name'].toString();
      name = name.split(',').take(3).join(',').trim();

      return SearchResult(
        name,
        LatLng(double.parse(item['lat']), double.parse(item['lon'])),
      );
    }).toList();
  }
}
