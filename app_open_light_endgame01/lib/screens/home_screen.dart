import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/device.dart';
import '../services/voice_service.dart';
import 'qr_scanner_screen.dart';
import 'device_control_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Device> devices = [];
  final String _storageKey = 'devices';
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    _voiceService.onCommandRecognized = (command) {
      setState(() {
        _lastCommand = command;
      });
      // Xử lý lệnh giọng nói ở đây
      if (command == 'on') {
        // Bật thiết bị
        _showMessage('Đã bật thiết bị');
      } else if (command == 'off') {
        // Tắt thiết bị
        _showMessage('Đã tắt thiết bị');
      }
    };

    _voiceService.onError = (error) {
      _showMessage('Lỗi: $error');
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson = prefs.getStringList(_storageKey) ?? [];
    setState(() {
      devices =
          devicesJson.map((json) => Device.fromJson(jsonDecode(json))).toList();
    });
  }

  Future<void> _saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final devicesJson =
        devices.map((device) => jsonEncode(device.toJson())).toList();
    await prefs.setStringList(_storageKey, devicesJson);
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null) {
      _showMessage('Đã quét QR code: $result');
      // Xử lý kết quả quét QR code ở đây
    }
  }

  Future<void> _toggleVoiceRecognition() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      await _voiceService.startListening();
      setState(() {
        _isListening = true;
      });
    }
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleVoiceRecognition,
                tooltip: _isListening ? 'Dừng lắng nghe' : 'Bắt đầu lắng nghe',
              ),
              TextButton(
                onPressed: _scanQRCode,
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (devices.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có thiết bị nào.\nNhấn "Thêm thiết bị" để quét QR code',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF222222),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceControlScreen(device: device),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.all(5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        size: 40,
                        color: device.isOn ? Colors.yellow : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF222222),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Thiết bị', 'Thêm thiết bị'),
            _buildDeviceList(),
          ],
        ),
      ),
    );
  }
}
