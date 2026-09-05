import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'main.dart';

class InterestScreen extends StatefulWidget {
  const InterestScreen({super.key});

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> {
  String _selectedPersona = "Commuter";
  bool _loading = false;
  String _responseMessage = "";

  final List<Map<String, dynamic>> _personas = [
    {"title": "Commuter", "icon": Icons.directions_bus, "desc": "Traffic & rain alerts"},
    {"title": "Farmer", "icon": Icons.agriculture, "desc": "Soil moisture & crop advisory"},
    {"title": "Fitness Enthusiast", "icon": Icons.fitness_center, "desc": "Best time for outdoor runs"},
    {"title": "Event Planner", "icon": Icons.event, "desc": "Outdoor risk assessment"},
  ];

  void _submitInterest() async {
    setState(() {
      _loading = true;
      _responseMessage = "";
    });

    try {
      final dio = Dio();
      await dio.post(
        'http://127.0.0.1:8000/api/set-interest',
        data: {"persona": _selectedPersona},
      );
      
      setState(() {
        _loading = false;
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(persona: _selectedPersona),
        ),
      );
      
    } catch (e) {
      setState(() {
        _responseMessage = "Error connecting to backend: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Your Persona"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              globalThemeNotifier.value = globalThemeNotifier.value == ThemeMode.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
            },
            icon: Icon(globalThemeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How will you use Mausam?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll customize your weather dashboard based on your choice.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _personas.length,
                itemBuilder: (context, index) {
                  final persona = _personas[index];
                  final isSelected = _selectedPersona == persona['title'];
                  return Card(
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.blue.shade800 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(persona['icon'], color: Colors.blue.shade800, size: 30),
                      title: Text(persona['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(persona['desc']),
                      trailing: Radio<String>(
                        value: persona['title'],
                        groupValue: _selectedPersona,
                        onChanged: (value) {
                          setState(() {
                            _selectedPersona = value!;
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          _selectedPersona = persona['title'];
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitInterest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text("Continue to Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_responseMessage.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text(
                _responseMessage,
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}