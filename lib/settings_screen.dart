import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final bool initialIsFahrenheit;

  const SettingsScreen({Key? key, required this.initialIsFahrenheit})
      : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isFahrenheit;

  @override
  void initState() {
    super.initState();
    _isFahrenheit = widget.initialIsFahrenheit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
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
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('温度単位を華氏で表示'),
            subtitle: const Text('オン: 華氏(℉) / オフ: 摂氏(℃)'),
            value: _isFahrenheit,
            onChanged: (bool newValue) {
              setState(() {
                _isFahrenheit = newValue;
              });
              // 設定が変更されたことを前の画面に伝える
              Navigator.of(context).pop(newValue);
            },
          ),
        ],
      ),
    );
  }
}
