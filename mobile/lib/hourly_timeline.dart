import 'package:flutter/material.dart';

class HourlyTimeline extends StatelessWidget {
  const HourlyTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy hourly data for now — later we can hook this up to OpenWeatherMap's 3-hour forecast API!
    final List<Map<String, dynamic>> hours = [
      {'time': '12 PM', 'temp': '31°C', 'icon': Icons.wb_sunny, 'rain': '0%'},
      {'time': '3 PM', 'temp': '33°C', 'icon': Icons.wb_sunny, 'rain': '10%'},
      {'time': '6 PM', 'temp': '29°C', 'icon': Icons.cloud, 'rain': '20%'},
      {'time': '9 PM', 'temp': '26°C', 'icon': Icons.nightlight_round, 'rain': '5%'},
      {'time': '12 AM', 'temp': '24°C', 'icon': Icons.nightlight_round, 'rain': '0%'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffdce6e4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Forecast',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xff12343b)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hours.length,
              itemBuilder: (context, index) {
                final item = hours[index];
                return Container(
                  width: 75,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f7f6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xffdce6e4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['time'], style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Icon(item['icon'], color: const Color(0xff19647e), size: 22),
                      const SizedBox(height: 6),
                      Text(item['temp'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff12343b))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}