import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WeatherApp(),
    );
  }
}

class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  String _temperature = '';
  String _description = '';
  String _iconCode = '';
  bool _isLoading = false;
  String? _error;
  List<String> _favoriteCities = []; // お気に入り都市リスト
  final TextEditingController _controller = TextEditingController(); // 入力取得

  Future<void> fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiKey = '5c0eb5159153499d04404e4d370b33fd';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=ja';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature = '${data['main']['temp']}℃';
          _description = data['weather'][0]['description'];
          _iconCode = data['weather'][0]['icon'];
        });
      } else {
        setState(() {
          _error = '天気情報を取得できませんでした（${response.statusCode}）';
        });
      }
    } catch (e) {
      setState(() {
        _error = '通信エラーが発生しました';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = '位置情報サービスが無効です';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = '位置情報の許可が必要です';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = '位置情報の許可が永久に拒否されています';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final apiKey = '5c0eb5159153499d04404e4d370b33fd';
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=ja';

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
        });
      }
    } catch (e) {
      setState(() {
        _error = '通信または位置情報エラー';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addToFavorites() {
    final city = _controller.text.trim();
    if (city.isNotEmpty && !_favoriteCities.contains(city)) {
      setState(() {
        _favoriteCities.add(city);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('天気アプリ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // スクロール可能
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                onSubmitted: fetchWeather,
                decoration: InputDecoration(
                  labelText: '都市名を入力',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => fetchWeather(_controller.text),
                      child: Text('天気を取得'),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addToFavorites,
                    child: Icon(Icons.favorite),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: fetchWeatherByLocation,
                child: Text('現在地の天気を取得'),
              ),
              SizedBox(height: 16),
              if (_isLoading)
                CircularProgressIndicator()
              else if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red))
              else ...[
                Text('気温: $_temperature'),
                Text('天気: $_description'),
                if (_iconCode.isNotEmpty)
                  Image.network(
                    'http://openweathermap.org/img/wn/$_iconCode@2x.png',
                    width: 100,
                    height: 100,
                  ),
              ],
              SizedBox(height: 24),
              if (_favoriteCities.isNotEmpty) ...[
                Text('お気に入り都市', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _favoriteCities
                      .map((city) => ElevatedButton(
                            onPressed: () => fetchWeather(city),
                            child: Text(city),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
