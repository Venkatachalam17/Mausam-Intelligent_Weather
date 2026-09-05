import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'interest_screen.dart';

// Global theme notifier so any screen can toggle it instantly!
final ValueNotifier<ThemeMode> globalThemeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MausamApp());
}

class MausamApp extends StatelessWidget {
  const MausamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: globalThemeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'Mausam Intelligent Weather',
          debugShowCheckedModeBanner: false,
          themeMode: currentTheme,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ApiService _apiService = ApiService();
  String _backendStatus = "Not connected yet";

  void _testBackend() async {
    setState(() {
      _backendStatus = "Connecting to FastAPI...";
    });
    
    final result = await _apiService.checkHealth();
    setState(() {
      _backendStatus = result['message'] ?? "Connected successfully!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              globalThemeNotifier.value = globalThemeNotifier.value == ThemeMode.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light;
            },
            icon: Icon(
              globalThemeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade300],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_queue, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "MAUSAM",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Weather that understands you.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InterestScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Get Started", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Text(
                  _backendStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}