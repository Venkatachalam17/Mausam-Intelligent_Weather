import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'hourly_timeline.dart';
import 'main.dart';
import 'map_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String persona;
  
  const DashboardScreen({
    super.key, 
    required this.persona,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _showPlan = true;
  String _currentLang = "en"; // Default to English
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
        'http://127.0.0.1:8000/api/dashboard/${widget.persona}?city=$city&lang=$_currentLang',
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
        'http://127.0.0.1:8000/api/dashboard/${widget.persona}?lat=${position.latitude}&lon=${position.longitude}&lang=$_currentLang',
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

  @override
  Widget build(BuildContext context) {
    final isDark = globalThemeNotifier.value == ThemeMode.dark;
    final isAlert = _weatherData['is_alert'] == true;
    final accent = isAlert ? const Color(0xffe26d5a) : (isDark ? const Color(0xff4ea8de) : const Color(0xff19647e));
    
    final bgColor = isDark ? const Color(0xff121212) : const Color(0xfff5f7f6);
    final cardColor = isDark ? const Color(0xff1e1e1e) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xff12343b);
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? const Color(0xff2c2c2c) : const Color(0xffdce6e4);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'MAUSAM',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        backgroundColor: isDark ? const Color(0xff1e1e1e) : const Color(0xff12343b),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: 'Select Language',
            onSelected: (String langCode) {
              setState(() {
                _currentLang = langCode;
              });
              _fetchDashboardData((_weatherData['location'] ?? 'Coimbatore').toString());
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'en', child: Text('English')),
              const PopupMenuItem<String>(value: 'ta', child: Text('தமிழ் (Tamil)')),
              const PopupMenuItem<String>(value: 'hi', child: Text('हिन्दी (Hindi)')),
            ],
          ),
          IconButton(
            onPressed: () {
              globalThemeNotifier.value = globalThemeNotifier.value == ThemeMode.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
              setState(() {});
            },
            icon: Icon(globalThemeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle theme',
          ),
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
                  _buildGreeting(accent, textColor),
                  const SizedBox(height: 18),
                  _buildSearch(accent, cardColor, textColor),
                  const SizedBox(height: 18),
                  _buildWeatherHero(isAlert),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: accent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentLang == 'ta' ? 'மௌசம் நுண்ணறிவு ஆலோசனை' : (_currentLang == 'hi' ? 'मौसम बुद्धिमत्ता सलाह' : 'Mausam Intelligence Advisory'),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (_weatherData['advice'] ?? '').toString(),
                          style: TextStyle(fontSize: 14, height: 1.4, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMetricGrid(cardColor, textColor, subTextColor, borderColor),
                  const SizedBox(height: 18),
                  const HourlyTimeline(),
                  const SizedBox(height: 22),
                  _buildPlanSection(accent, cardColor, textColor, subTextColor, borderColor),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(persona: widget.persona),
                      ),
                    ),
                    icon: const Icon(Icons.layers_outlined),
                    label: Text(_currentLang == 'ta' ? 'நேரலை வானிலை வரைபடத்தை ஆராயுங்கள்' : (_currentLang == 'hi' ? 'लाइव मौसम मानचित्र देखें' : 'Explore the live weather map')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: borderColor),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting(Color accent, Color textColor) {
    final headlineText = (_weatherData['headline'] ?? '').toString();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentLang == 'ta' ? 'வணக்கம், ${widget.persona}' : (_currentLang == 'hi' ? 'नमस्ते, ${widget.persona}' : 'Good day, ${widget.persona}'),
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                headlineText,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.wb_twilight, color: Color(0xffe4a853), size: 42),
      ],
    );
  }

  Widget _buildSearch(Color accent, Color cardColor, Color textColor) => TextField(
    controller: _cityController,
    style: TextStyle(color: textColor),
    onSubmitted: (city) {
      if (city.trim().isNotEmpty) _fetchDashboardData(city.trim());
    },
    decoration: InputDecoration(
      hintText: _currentLang == 'ta' ? 'மற்றொரு நகரத்தைத் தேடுங்கள்' : (_currentLang == 'hi' ? 'दूसरा शहर खोजें' : 'Search another city'),
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
      prefixIcon: Icon(Icons.search, color: textColor),
      suffixIcon: IconButton(
        onPressed: _fetchCurrentLocationWeather,
        icon: const Icon(Icons.gps_fixed),
        color: accent,
        tooltip: 'Use current location',
      ),
      filled: true,
      fillColor: cardColor,
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
            // Map button placed nicely right on the top-left/top-right of the hero card
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapScreen(persona: widget.persona),
                ),
              ),
              icon: const Icon(Icons.map_outlined, color: Colors.white70, size: 22),
              tooltip: 'Live Weather Map',
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            if (isAlert) ...[
              const SizedBox(width: 10),
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
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
          _currentLang == 'ta'
              ? 'உணர்வு ${_weatherData['feels_like'] ?? '--'}  •  ${_weatherData['risk_level'] ?? 'குறைந்த ஆபத்து'}'
              : (_currentLang == 'hi'
                  ? 'महसूस होता है ${_weatherData['feels_like'] ?? '--'}  •  ${_weatherData['risk_level'] ?? 'कम जोखिम'}'
                  : 'Feels like ${_weatherData['feels_like'] ?? '--'}  •  ${_weatherData['risk_level'] ?? 'Low Risk'}'),
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _buildMetricGrid(Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final hLabel = _currentLang == 'ta' ? 'ஈரப்பதம்' : (_currentLang == 'hi' ? 'नमी' : 'Humidity');
    final wLabel = _currentLang == 'ta' ? 'காற்று' : (_currentLang == 'hi' ? 'हवा' : 'Wind');
    final vLabel = _currentLang == 'ta' ? 'दृश्यता' : (_currentLang == 'hi' ? 'दृश्यता' : 'Visibility');
    final pLabel = _currentLang == 'ta' ? 'அழுத்தம்' : (_currentLang == 'hi' ? 'दवाब' : 'Pressure');

    final metrics = [
      [hLabel, _weatherData['humidity'] ?? '--', Icons.water_drop_outlined],
      [wLabel, _weatherData['wind_speed'] ?? '--', Icons.air],
      [vLabel, _weatherData['visibility'] ?? '--', Icons.visibility_outlined],
      [pLabel, _weatherData['pressure'] ?? '--', Icons.speed],
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
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
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
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          metric[1].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: textColor,
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

  Widget _buildPlanSection(Color accent, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    final List planList = _weatherData['plan_items'] ?? [
      'Check for excess moisture before watering.',
      'Review irrigation needs before midday.',
      'Protect young plants from peak heat.'
    ];

    final planTitle = _currentLang == 'ta' ? 'உங்கள் வானிலை திட்டம்' : (_currentLang == 'hi' ? 'आपकी मौसम योजना' : 'Your weather plan');
    final planSubtitle = _currentLang == 'ta' ? 'உங்கள் நாளுக்கான எளிய செயல்கள்' : (_currentLang == 'hi' ? 'आपके दिन के लिए सरल उपाय' : 'Simple actions for your day');

    final icons = [Icons.water_drop_outlined, Icons.grass, Icons.air];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(18, 6, 10, 2),
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: .12),
              child: Icon(Icons.checklist_rounded, color: accent),
            ),
            title: Text(
              planTitle,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: textColor),
            ),
            subtitle: Text(planSubtitle, style: TextStyle(color: subTextColor)),
            trailing: IconButton(
              onPressed: () => setState(() => _showPlan = !_showPlan),
              icon: Icon(_showPlan ? Icons.expand_less : Icons.expand_more, color: textColor),
            ),
          ),
          if (_showPlan)
            ...List.generate(planList.length, (index) {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(
                  icons[index % icons.length],
                  color: accent,
                  size: 21,
                ),
                title: Text(
                  planList[index].toString(),
                  style: TextStyle(fontSize: 14, height: 1.3, color: textColor),
                ),
              );
            }),
        ],
      ),
    );
  }
}