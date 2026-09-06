import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'services/api_service.dart';

class MapScreen extends StatefulWidget {
  final String persona;
  const MapScreen({super.key, required this.persona});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedLayer = "temp"; // temp, rain, wind, humidity, pressure
  LatLng _selectedPosition = const LatLng(11.0168, 76.9558);
  Map<String, dynamic> _clickedWeatherData = {};
  bool _isLoadingPoint = false;
  late final MapOptions _mapOptions;
  final ApiService _apiService = ApiService();

  // Preset locations list, but users can click anywhere else too!
  final List<Map<String, dynamic>> _presetLocations = [
    {
      "name": "Coimbatore",
      "lat": 11.0168,
      "lng": 76.9558,
      "temp": "32°C",
      "risk": "Low Risk",
    },
    {
      "name": "Chennai",
      "lat": 13.0827,
      "lng": 80.2707,
      "temp": "35°C",
      "risk": "Moderate Risk",
    },
    {
      "name": "Bengaluru",
      "lat": 12.9716,
      "lng": 77.5946,
      "temp": "27°C",
      "risk": "Low Risk",
    },
    {
      "name": "Mumbai",
      "lat": 19.0760,
      "lng": 72.8777,
      "temp": "31°C",
      "risk": "High Weather Risk",
    },
    {
      "name": "Delhi",
      "lat": 28.6139,
      "lng": 77.2090,
      "temp": "38°C",
      "risk": "Moderate Risk",
    },
    {
      "name": "Kolkata",
      "lat": 22.5726,
      "lng": 88.3639,
      "temp": "34°C",
      "risk": "High Weather Risk",
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapOptions = MapOptions(
      initialCenter: _selectedPosition,
      initialZoom: 4.8,
      cameraConstraint: CameraConstraint.contain(
        bounds: LatLngBounds(const LatLng(6.5, 68.0), const LatLng(37.5, 97.5)),
      ),
      onTap: (tapPosition, latLng) {
        setState(() {
          _selectedPosition = latLng;
        });
        _fetchWeatherForCoordinates(latLng.latitude, latLng.longitude);
      },
    );
    _fetchWeatherForCoordinates(
      _selectedPosition.latitude,
      _selectedPosition.longitude,
    );
  }

  void _fetchWeatherForCoordinates(double lat, double lng) async {
    setState(() {
      _isLoadingPoint = true;
    });

    try {
      // Route through your backend dashboard API for robust live data fetch
      final response = await _apiService.dio.get(
        '/api/dashboard/${widget.persona}',
        queryParameters: {'lat': lat, 'lon': lng},
      );

      if (!mounted) return;

      // Map the backend response fields to match what the map UI expects
      final data = response.data;
      setState(() {
        _clickedWeatherData = {
          'name': data['location'] ?? 'Custom Location',
          'weather': [
            {'description': data['condition'] ?? 'Clear'},
          ],
          'main': {
            'temp':
                double.tryParse(
                  data['temperature'].toString().replaceAll('°C', ''),
                ) ??
                30.0,
            'humidity':
                int.tryParse(data['humidity'].toString().replaceAll('%', '')) ??
                65,
          },
          'wind': {
            'speed':
                double.tryParse(
                  data['wind_speed'].toString().replaceAll(' m/s', ''),
                ) ??
                4.5,
          },
        };
        _isLoadingPoint = false;
      });
    } catch (e) {
      print("🔥 MAP WEATHER ERROR: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingPoint = false;
        _clickedWeatherData = {'name': 'Error fetching location weather'};
      });
    }
  }

  // Map OpenWeather map layer codes based on user selection
  String _getLayerTileUrl() {
    const apiKey = "181e14f619b9946b6fae721dbe3c5cf4";
    switch (_selectedLayer) {
      case "rain":
        return 'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=$apiKey';
      case "wind":
        return 'https://tile.openweathermap.org/map/wind_new/{z}/{x}/{y}.png?appid=$apiKey';
      case "humidity":
        return 'https://tile.openweathermap.org/map/humidity_new/{z}/{x}/{y}.png?appid=$apiKey';
      case "pressure":
        return 'https://tile.openweathermap.org/map/pressure_new/{z}/{x}/{y}.png?appid=$apiKey';
      case "temp":
      default:
        return 'https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=$apiKey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.persona} Weather Intelligence Map",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            options: _mapOptions,
            children: [
              // Base Street Tile
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mausam',
              ),
              // Weather Data Overlay Tile (Temp, Rain, Wind, etc.)
              TileLayer(
                urlTemplate: _getLayerTileUrl(),
                userAgentPackageName: 'com.example.mausam',
                tileBuilder: (context, child, tile) {
                  return Opacity(opacity: 0.65, child: child);
                },
              ),
              // Preset Markers across India + Clicked Marker
              MarkerLayer(
                markers: [
                  ..._presetLocations.map((loc) {
                    bool isHighRisk = loc['risk'] == "High Weather Risk";
                    return Marker(
                      point: LatLng(loc['lat'], loc['lng']),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPosition = LatLng(loc['lat'], loc['lng']);
                          });
                          _fetchWeatherForCoordinates(loc['lat'], loc['lng']);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isHighRisk
                                    ? Colors.red
                                    : Colors.blue.shade800,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                loc['temp'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.location_on,
                              color: isHighRisk
                                  ? Colors.red.shade900
                                  : Colors.blue.shade900,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Active Selection Marker
                  Marker(
                    point: _selectedPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.purple,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Floating Filter Buttons on the Side (Rain, Wind, Temp, Humidity, Pressure)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Weather Layers",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _buildLayerButton("🌡️ Temp", "temp"),
                  _buildLayerButton("🌧️ Rain", "rain"),
                  _buildLayerButton("💨 Wind", "wind"),
                  _buildLayerButton("💧 Humidity", "humidity"),
                  _buildLayerButton("🌀 Pressure", "pressure"),
                ],
              ),
            ),
          ),

          // Bottom Popup Card showing real-time details of clicked/selected coordinate
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoadingPoint
                    ? const Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : _clickedWeatherData.isEmpty
                    ? const Text(
                        "Tap anywhere on the map to inspect weather conditions.",
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final locationDetails = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _clickedWeatherData['name'] ??
                                    "Custom Location",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Condition: ${_clickedWeatherData['weather']?[0]['description']?.toUpperCase() ?? '--'}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                          final weatherDetails = Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoChip(
                                "Temp",
                                "${(_clickedWeatherData['main']['temp'] ?? 0).round()}°C",
                              ),
                              _infoChip(
                                "Wind",
                                "${_clickedWeatherData['wind']['speed']} m/s",
                              ),
                              _infoChip(
                                "Humidity",
                                "${_clickedWeatherData['main']['humidity']}%",
                              ),
                            ],
                          );

                          if (constraints.maxWidth < 520) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                locationDetails,
                                const SizedBox(height: 12),
                                weatherDetails,
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [locationDetails, weatherDetails],
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerButton(String label, String layerKey) {
    bool isSelected = _selectedLayer == layerKey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedLayer = layerKey;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Colors.blue.shade800
              : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(90, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _infoChip(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
