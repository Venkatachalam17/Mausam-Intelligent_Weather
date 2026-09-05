import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'map_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String persona;
  const DashboardScreen({super.key, required this.persona});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _showPlan = true;
  Map<String, dynamic> _weatherData = {};
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData('Coimbatore');
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData(String city) async {
    setState(() => _loading = true);
    try {
      final response = await Dio().get(
        'http://127.0.0.1:8000/api/dashboard/${widget.persona}?city=$city',
      );
      if (!mounted) return;
      setState(() {
        _weatherData = Map<String, dynamic>.from(response.data);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchCurrentLocationWeather() async {
    setState(() => _loading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final response = await Dio().get(
        'http://127.0.0.1:8000/api/dashboard/${widget.persona}?lat=${position.latitude}&lon=${position.longitude}',
      );
      if (!mounted) return;
      setState(() {
        _weatherData = Map<String, dynamic>.from(response.data);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _number(String key) {
    final value = _weatherData[key]?.toString() ?? '';
    return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  IconData _conditionIcon() {
    final condition = (_weatherData['condition'] ?? '')
        .toString()
        .toLowerCase();
    if (condition.contains('rain') || condition.contains('drizzle')) {
      return Icons.cloudy_snowing;
    }
    if (condition.contains('cloud')) {
      return Icons.cloud;
    }
    if (condition.contains('storm') || condition.contains('thunder')) {
      return Icons.thunderstorm;
    }
    return Icons.wb_sunny;
  }

  String _personalHeadline() {
    final temp = _number('temperature');
    final humidity = _number('humidity');
    if (widget.persona == 'Farmer') {
      return humidity > 70
          ? 'A humid day for your fields'
          : 'A workable day for your fields';
    }
    if (widget.persona == 'Fitness Enthusiast') {
      return temp > 32
          ? 'Keep your workout light today'
          : 'Good energy for getting outside';
    }
    if (widget.persona == 'Event Planner') {
      return _weatherData['is_alert'] == true
          ? 'Build a weather backup into your plan'
          : 'Your outdoor window looks promising';
    }
    return _weatherData['is_alert'] == true
        ? 'Allow extra time for your commute'
        : 'Your commute window looks comfortable';
  }

  List<Map<String, dynamic>> _planItems() {
    final temp = _number('temperature');
    final humidity = _number('humidity');
    final wind = _number('wind_speed');
    final rainy = (_weatherData['condition'] ?? '')
        .toString()
        .toLowerCase()
        .contains('rain');
    if (widget.persona == 'Farmer') {
      return [
        {
          'icon': Icons.water_drop_outlined,
          'text': humidity > 70
              ? 'Check for excess moisture before watering.'
              : 'Review irrigation needs before midday.',
        },
        {
          'icon': Icons.grass,
          'text': temp > 34
              ? 'Protect young plants from peak heat.'
              : 'A good window for field work.',
        },
        {
          'icon': Icons.air,
          'text': wind > 8
              ? 'Secure lightweight covers and equipment.'
              : 'Wind conditions are manageable.',
        },
      ];
    }
    if (widget.persona == 'Fitness Enthusiast') {
      return [
        {
          'icon': Icons.schedule,
          'text': temp > 32
              ? 'Choose an early or late workout window.'
              : 'Aim for an outdoor session today.',
        },
        {
          'icon': Icons.water_drop_outlined,
          'text': humidity > 70
              ? 'Carry extra water and take recovery breaks.'
              : 'Hydration needs look normal.',
        },
        {
          'icon': Icons.directions_run,
          'text': rainy
              ? 'Have an indoor backup ready.'
              : 'Outdoor movement looks comfortable.',
        },
      ];
    }
    if (widget.persona == 'Event Planner') {
      return [
        {
          'icon': Icons.umbrella_outlined,
          'text': rainy
              ? 'Keep a covered area ready for guests.'
              : 'No rain signal in the current conditions.',
        },
        {
          'icon': Icons.air,
          'text': wind > 8
              ? 'Recheck decor, signage, and lightweight structures.'
              : 'Wind should be friendly to setup.',
        },
        {
          'icon': Icons.access_time,
          'text': temp > 34
              ? 'Schedule setup before the afternoon heat.'
              : 'The current temperature is event-friendly.',
        },
      ];
    }
    return [
      {
        'icon': rainy ? Icons.umbrella_outlined : Icons.directions_walk,
        'text': rainy
            ? 'Carry rain protection for the journey.'
            : 'Walking conditions look comfortable.',
      },
      {
        'icon': Icons.traffic,
        'text': wind > 8
            ? 'Allow extra time on exposed routes.'
            : 'No wind-related travel concern right now.',
      },
      {
        'icon': Icons.wb_sunny_outlined,
        'text': temp > 34
            ? 'Prefer shade and avoid the hottest travel window.'
            : 'A light layer should be enough.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isAlert = _weatherData['is_alert'] == true;
    final accent = isAlert ? const Color(0xffe26d5a) : const Color(0xff19647e);
    return Scaffold(
      backgroundColor: const Color(0xfff5f7f6),
      appBar: AppBar(
        title: const Text(
          'MAUSAM',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        backgroundColor: const Color(0xff12343b),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _fetchCurrentLocationWeather,
            icon: const Icon(Icons.my_location),
            tooltip: 'Use current location',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weatherData.containsKey('error')
          ? Center(
              child: Text(
                _weatherData['error'].toString(),
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchDashboardData(
                (_weatherData['location'] ?? 'Coimbatore').toString(),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _buildGreeting(accent),
                  const SizedBox(height: 18),
                  _buildSearch(accent),
                  const SizedBox(height: 18),
                  _buildWeatherHero(isAlert),
                  const SizedBox(height: 16),
                  _buildMetricGrid(),
                  const SizedBox(height: 22),
                  _buildPlanSection(accent),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(persona: widget.persona),
                      ),
                    ),
                    icon: const Icon(Icons.layers_outlined),
                    label: const Text('Explore the live weather map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff12343b),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Color(0xff9bb7b9)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting(Color accent) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good day, ${widget.persona}',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _personalHeadline(),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Color(0xff12343b),
              ),
            ),
          ],
        ),
      ),
      const Icon(Icons.wb_twilight, color: Color(0xffe4a853), size: 42),
    ],
  );

  Widget _buildSearch(Color accent) => TextField(
    controller: _cityController,
    onSubmitted: (city) {
      if (city.trim().isNotEmpty) _fetchDashboardData(city.trim());
    },
    decoration: InputDecoration(
      hintText: 'Search another city',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        onPressed: _fetchCurrentLocationWeather,
        icon: const Icon(Icons.gps_fixed),
        color: accent,
        tooltip: 'Use current location',
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildWeatherHero(bool isAlert) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isAlert
            ? const [Color(0xffa53f35), Color(0xffe49b54)]
            : const [Color(0xff12343b), Color(0xff19647e)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                (_weatherData['location'] ?? 'Location').toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            if (isAlert)
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(_conditionIcon(), color: const Color(0xffffd166), size: 58),
            const SizedBox(width: 16),
            Text(
              (_weatherData['temperature'] ?? '--').toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          (_weatherData['condition'] ?? '').toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Feels like ${_weatherData['feels_like'] ?? '--'}  •  ${_weatherData['risk_level'] ?? 'Low Risk'}',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _buildMetricGrid() {
    final metrics = [
      ['Humidity', _weatherData['humidity'] ?? '--', Icons.water_drop_outlined],
      ['Wind', _weatherData['wind_speed'] ?? '--', Icons.air],
      [
        'Visibility',
        _weatherData['visibility'] ?? '--',
        Icons.visibility_outlined,
      ],
      ['Pressure', _weatherData['pressure'] ?? '--', Icons.speed],
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: metrics
          .map(
            (metric) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffdce6e4)),
              ),
              child: Row(
                children: [
                  Icon(
                    metric[2] as IconData,
                    color: const Color(0xff19647e),
                    size: 23,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          metric[0] as String,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          metric[1].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPlanSection(Color accent) {
    final items = _planItems();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffdce6e4)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(18, 6, 10, 2),
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: .12),
              child: Icon(Icons.checklist_rounded, color: accent),
            ),
            title: const Text(
              'Your weather plan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            subtitle: const Text('Simple actions for your day'),
            trailing: IconButton(
              onPressed: () => setState(() => _showPlan = !_showPlan),
              icon: Icon(_showPlan ? Icons.expand_less : Icons.expand_more),
            ),
          ),
          if (_showPlan)
            ...items.map(
              (item) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(
                  item['icon'] as IconData,
                  color: accent,
                  size: 21,
                ),
                title: Text(
                  item['text'] as String,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
