import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const FlutterAIApp());
}

class FlutterAIApp extends StatelessWidget {
  const FlutterAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter AI Assistant',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.deepPurple.shade50,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String _output = "";
  bool _isLoading = false;

  Future<void> fetchFlutterCode(String input) async {
    setState(() {
      _isLoading = true;
    });

    const prompt = "You are an AI assistant specializing in Flutter. "
        "Answer only with valid Flutter Dart code. If the query is unrelated, "
        "respond with: 'I only handle Flutter development tasks.'";

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': input},
          ],
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _output = data['choices'][0]['message']['content'].trim();
        });
      } else {
        print('Error: ${response.body}');
        setState(() {
          _output = "Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _output = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveToFile(String code) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/generated_code.dart');
      await file.writeAsString(code);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Code saved to ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter AI Assistant'),
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade100, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_output.isNotEmpty)
                      Card(
                        elevation: 4,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SelectableText(
                            _output,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6.0,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your Flutter query...',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.deepPurple.shade300,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  backgroundColor: Colors.orange,
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_controller.text.trim().isNotEmpty) {
                            fetchFlutterCode(_controller.text.trim());
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
