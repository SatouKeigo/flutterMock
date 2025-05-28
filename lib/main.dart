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
  String? _iconCode;
  String? _error;
  bool _isLoading = false;

  Future<void> fetchWeather(String city) async {
    final apiKey = '5c0eb5159153499d04404e4d370b33fd';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=ja';

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature = '${data['main']['temp']}℃';
          _description = data['weather'][0]['description'];
          _iconCode = data['weather'][0]['icon'];
          _error = null;
        });
      } else {
        setState(() {
          _error = '天気情報を取得できませんでした（${response.statusCode}）';
          _temperature = null;
          _description = null;
          _iconCode = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = '通信エラーが発生しました';
        _temperature = null;
        _description = null;
        _iconCode = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
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
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: '都市名を入力してください',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => fetchWeather(_controller.text),
                      child: Text('天気を取得'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            if (_temperature != null && _description != null && !_isLoading)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_iconCode != null)
                        Image.network(
                          'https://openweathermap.org/img/wn/$_iconCode@2x.png',
                          width: 100,
                          height: 100,
                        ),
                      Text(
                        '気温：$_temperature',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '天気：$_description',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
