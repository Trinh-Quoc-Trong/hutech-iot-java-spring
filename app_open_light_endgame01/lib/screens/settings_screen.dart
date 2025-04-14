import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'vi';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
      _language = prefs.getString('language') ?? 'vi';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notifications', _notifications);
    await prefs.setString('language', _language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Chế độ tối'),
            subtitle: const Text('Bật/tắt chế độ tối'),
            trailing: Switch(
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
                _saveSettings();
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Thông báo'),
            subtitle: const Text('Bật/tắt thông báo'),
            trailing: Switch(
              value: _notifications,
              onChanged: (value) {
                setState(() {
                  _notifications = value;
                });
                _saveSettings();
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Ngôn ngữ'),
            subtitle: const Text('Chọn ngôn ngữ'),
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                  });
                  _saveSettings();
                }
              },
              items: const [
                DropdownMenuItem(
                  value: 'vi',
                  child: Text('Tiếng Việt'),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Thông tin ứng dụng'),
            subtitle: const Text('Phiên bản 1.0.0'),
            trailing: const Icon(Icons.info),
            onTap: () {
              // Hiển thị thông tin ứng dụng
            },
          ),
        ],
      ),
    );
  }
}
