import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'map_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String persona;
  const DashboardScreen({super.key, required this.persona});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _weatherData = {};
  final TextEditingController _cityController = TextEditingController();
  
  bool _isGeneratingAdvice = false;
  String _displayedAdvice = "";
  bool _hasRequestedAdvice = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData("Coimbatore");
  }

  void _fetchDashboardData(String city) async {
    setState(() {
      _loading = true;
      _hasRequestedAdvice = false;
      _displayedAdvice = "";
    });

    try {
      final dio = Dio();
      final response = await dio.get('http://127.0.0.1:8000/api/dashboard/${widget.persona}?city=$city');
      setState(() {
        _weatherData = response.data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _startTypewriterEffect() async {
    final String fullText = _weatherData['advice'] ?? "No advice available.";
    setState(() {
      _isGeneratingAdvice = true;
      _hasRequestedAdvice = true;
      _displayedAdvice = "";
    });

    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      if (!mounted) return;
      setState(() {
        _displayedAdvice = fullText.substring(0, i + 1);
      });
    }

    setState(() {
      _isGeneratingAdvice = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isAlert = _weatherData['is_alert'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.persona} Dashboard", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: isAlert ? Colors.red.shade800 : Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Enter city (e.g. London, Tokyo)...",
                      hintStyle: const TextStyle(fontSize: 15),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_cityController.text.isNotEmpty) {
                      _fetchDashboardData(_cityController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlert ? Colors.red.shade800 : Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.search, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _loading
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                : _weatherData.containsKey('error')
                    ? Center(child: Text(_weatherData['error'], style: const TextStyle(color: Colors.red, fontSize: 18)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAlert) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade400, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 32),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      "SEVERE WEATHER WARNING: High risk conditions detected!",
                                      style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isAlert 
                                    ? [Colors.red.shade700, Colors.orange.shade600]
                                    : [Colors.blue.shade700, Colors.blue.shade400],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_weatherData['location'] ?? "Location", style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(_weatherData['temperature'] ?? "--", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                                Text(_weatherData['condition'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 12),
                                Text("Feels like: ${_weatherData['feels_like'] ?? '--'}  |  Risk: ${_weatherData['risk_level'] ?? 'Normal'}", style: const TextStyle(color: Colors.white70, fontSize: 15)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 2.2,
                            children: [
                              _buildMetricCard("Humidity", _weatherData['humidity'] ?? '--', Icons.water_drop),
                              _buildMetricCard("Wind Speed", _weatherData['wind_speed'] ?? '--', Icons.air),
                              _buildMetricCard("Visibility", _weatherData['visibility'] ?? '--', Icons.visibility),
                              _buildMetricCard("Pressure", _weatherData['pressure'] ?? '--', Icons.speed),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreen(persona: widget.persona),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.map, size: 22),
                              label: const Text("Open Live Weather Map", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Mausam AI Smart Advisory", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                onPressed: _isGeneratingAdvice ? null : _startTypewriterEffect,
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: Text(_hasRequestedAdvice ? "Regenerate" : "Ask Mausam AI", style: const TextStyle(fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_hasRequestedAdvice)
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.purple.shade600, size: 30),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        _displayedAdvice,
                                        style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}