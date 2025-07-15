import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ソラミル',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      home: WeatherApp(),
      debugShowCheckedModeBanner: false,
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
  List<String> _favoriteCities = [];
  final TextEditingController _controller = TextEditingController();

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
          _error = '天気情報を取得できません（${response.statusCode}）';
        });
      }
    } catch (e) {
      setState(() {
        _error = '通信エラー';
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
        _error = '位置情報サービスが無効です';
        _isLoading = false;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = '位置情報の許可が必要です';
          _isLoading = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = '位置情報の許可が永久に拒否されています';
        _isLoading = false;
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
        });
      } else {
        _error = '天気情報を取得できません（${response.statusCode}）';
      }
    } catch (e) {
      _error = '通信または位置情報エラー';
    } finally {
      _isLoading = false;
      setState(() {});
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
        title:
            const Text('ソラミル', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlueAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 入力欄
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: '都市名を入力',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => fetchWeather(_controller.text),
                      icon: Icon(Icons.cloud, color: Colors.white),
                      label: Text('天気取得'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        foregroundColor: Colors.white, // 文字色を白に
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addToFavorites,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(14),
                      foregroundColor: Colors.white, // アイコン色白に
                    ),
                    child: Icon(Icons.favorite, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: fetchWeatherByLocation,
                icon: Icon(Icons.my_location, color: Colors.white),
                label: Text('現在地の天気'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, // 文字色白に
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),

              // 天気表示カード
              if (_isLoading)
                CircularProgressIndicator()
              else if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red))
              else if (_temperature.isNotEmpty)
                Card(
                  color: Colors.lightBlue[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('気温: $_temperature',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('天気: $_description',
                            style: TextStyle(fontSize: 20)),
                        if (_iconCode.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Image.network(
                              'http://openweathermap.org/img/wn/$_iconCode@2x.png',
                              width: 100,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              if (_favoriteCities.isNotEmpty) ...[
                Text('お気に入り都市',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _favoriteCities
                      .map<Widget>((city) => InputChip(
                            label: Text(city),
                            backgroundColor: Colors.blue[100],
                            onPressed: () => fetchWeather(city),
                            onDeleted: () {
                              setState(() {
                                _favoriteCities.remove(city);
                              });
                            },
                            deleteIcon: Icon(Icons.close),
                          ))
                      .toList(),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
