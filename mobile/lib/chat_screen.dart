import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      "sender": "bot",
      "message": "Yoo! Ask me anything about the weather, travel plans, or clothing advice! 🌤️",
    },
  ];
  bool _loading = false;

  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "message": text});
      _loading = true;
    });
    _controller.clear();

    try {
      final response = await _apiService.dio.get(
        '/api/chat',
        queryParameters: {'message': text},
      );

      String botReply = response.data['reply'] ?? "Got it!";
      setState(() {
        _messages.add({"sender": "bot", "message": botReply});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "sender": "bot",
          "message": "Network error! Check your connection.",
        });
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mausam AI Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]["sender"] == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _messages[index]["message"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about weather or suggestions...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
