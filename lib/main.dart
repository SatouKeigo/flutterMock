import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/settings_screen.dart'; // settings_screen.dart をインポート

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
  String _currentPressure = '';
  String _headacheWarning = '';

  bool _isLoading = false;
  String? _error;
  List<String> _favoriteCities = [];
  final TextEditingController _controller = TextEditingController();

  // 温度表示単位の状態を追加
  bool _isFahrenheit = false; // false: 摂氏(℃), true: 華氏(℉)

  // 温度を現在の単位設定に合わせてフォーマットするヘルパー関数
  String _formatTemperature(double tempInCelsius) {
    if (_isFahrenheit) {
      final double tempInFahrenheit = (tempInCelsius * 9 / 5) + 32;
      return '${tempInFahrenheit.toStringAsFixed(1)}℉'; // 小数点以下1桁まで表示
    } else {
      return '${tempInCelsius.toStringAsFixed(1)}℃';
    }
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _headacheWarning = '';
      _currentPressure = '';
      _temperature = '';
      _description = '';
      _iconCode = '';
    });

    final apiKey = '5c0eb5159153499d04404e4d370b33fd';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=ja'; // APIからは常に摂氏(metric)で取得

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature =
              _formatTemperature(data['main']['temp'].toDouble()); // ヘルパー関数を使用
          _description = data['weather'][0]['description'];
          _iconCode = data['weather'][0]['icon'];
          _currentPressure = '${data['main']['pressure']} hPa';
          _headacheWarning =
              _getHeadacheWarning(data['main']['pressure'].toDouble());
        });
      } else {
        setState(() {
          _error = '天気情報を取得できません（${response.statusCode}）';
        });
      }
    } catch (e) {
      setState(() {
        _error = '通信エラー: ${e.toString()}';
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
      _temperature = '';
      _description = '';
      _iconCode = '';
      _currentPressure = '';
      _headacheWarning = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = '位置情報サービスが無効です';
        _isLoading = false;
        setState(() {});
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = '位置情報の許可が必要です';
          _isLoading = false;
          setState(() {});
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = '位置情報の許可が永久に拒否されています。設定から変更してください。';
        _isLoading = false;
        setState(() {});
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
          _temperature =
              _formatTemperature(data['main']['temp'].toDouble()); // ヘルパー関数を使用
          _description = data['weather'][0]['description'];
          _iconCode = data['weather'][0]['icon'];
          _currentPressure = '${data['main']['pressure']} hPa';
          _headacheWarning =
              _getHeadacheWarning(data['main']['pressure'].toDouble());
        });
      } else {
        _error = '天気情報を取得できませんでした（${response.statusCode}）';
      }
    } catch (e) {
      _error = '通信または位置情報エラー: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getHeadacheWarning(double currentPressure) {
    if (currentPressure < 1005) {
      return '気圧が低めです。体調にお気をつけください。';
    } else if (currentPressure < 1000) {
      return '【片頭痛注意！】気圧が低いです。無理をしないでください。';
    }
    return '今日の気圧は比較的安定しています。';
  }

  void _addToFavorites() {
    final city = _controller.text.trim();
    if (city.isNotEmpty && !_favoriteCities.contains(city)) {
      setState(() {
        _favoriteCities.add(city);
      });
    }
  }

  // 設定画面に遷移する関数
  void _navigateToSettings() async {
    final newIsFahrenheit = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            SettingsScreen(initialIsFahrenheit: _isFahrenheit),
      ),
    );

    // 設定画面から戻り値があれば、温度単位を更新
    if (newIsFahrenheit != null && newIsFahrenheit != _isFahrenheit) {
      setState(() {
        _isFahrenheit = newIsFahrenheit;
        // 温度単位が変更されたら、表示を更新するために再計算
        if (_temperature.isNotEmpty) {
          // 現在の_temperatureから数値を抽出し、再フォーマットする
          // ここでは簡易的に、現在の表示が摂氏であると仮定して変換
          try {
            double tempValue;
            if (_temperature.endsWith('℃')) {
              tempValue = double.parse(_temperature.replaceAll('℃', ''));
            } else if (_temperature.endsWith('℉')) {
              // 既に華氏表示の場合、一旦摂氏に戻してから再計算
              tempValue =
                  (double.parse(_temperature.replaceAll('℉', '')) - 32) * 5 / 9;
            } else {
              tempValue = 0.0; // デフォルト値
            }
            _temperature = _formatTemperature(tempValue);
          } catch (e) {
            print("温度変換エラー: $e");
          }
        }
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white), // 設定アイコンを追加
            onPressed: _navigateToSettings, // 設定画面への遷移
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                        foregroundColor: Colors.white,
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
                      foregroundColor: Colors.white,
                    ),
                    child: Icon(Icons.favorite, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: fetchWeatherByLocation,
                icon: Icon(Icons.my_location, color: Colors.white),
                label: Text('現在地の天気と気圧'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                CircularProgressIndicator()
              else if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16))
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
                        if (_headacheWarning.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _headacheWarning,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_currentPressure.isNotEmpty)
                          Text('気圧: $_currentPressure',
                              style: TextStyle(fontSize: 20)),
                        SizedBox(height: 16),
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
