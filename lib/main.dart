import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '天気アプリ',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  String? _temperature;
  String? _description;
  String? _error;

  Future<void> fetchWeather(String city) async {
    final apiKey =
        '5c0eb5159153499d04404e4d370b33fd'; // ← OpenWeatherMapのAPIキーを入れてね
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=ja';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature = '${data['main']['temp']}℃';
          _description = data['weather'][0]['description'];
          _error = null;
        });
      } else {
        setState(() {
          _error = '天気情報を取得できませんでした（${response.statusCode}）';
          _temperature = null;
          _description = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = '通信エラーが発生しました';
        _temperature = null;
        _description = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('天気アプリ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: '都市名を入力してください'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => fetchWeather(_controller.text),
              child: Text('天気を取得'),
            ),
            SizedBox(height: 20),
            if (_temperature != null && _description != null) ...[
              Text('気温：$_temperature', style: TextStyle(fontSize: 20)),
              Text('天気：$_description', style: TextStyle(fontSize: 20)),
            ],
            if (_error != null) ...[
              SizedBox(height: 20),
              Text(_error!, style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
