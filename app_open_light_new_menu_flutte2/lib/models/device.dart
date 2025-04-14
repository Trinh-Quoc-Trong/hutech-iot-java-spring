import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Device {
  final String id;
  final String name;
  final String broker;
  final int port;
  final String topic;
  final String type;
  bool isOn;

  Device({
    required this.id,
    required this.name,
    required this.broker,
    required this.port,
    required this.topic,
    required this.type,
    this.isOn = false,
  });

  // Chuyển đổi Device thành Map để lưu vào SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'broker': broker,
      'port': port,
      'topic': topic,
      'type': type,
      'isOn': isOn,
    };
  }

  // Tạo Device từ Map (khi đọc từ SharedPreferences)
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      broker: json['broker'],
      port: json['port'],
      topic: json['topic'],
      type: json['type'],
      isOn: json['isOn'] ?? false,
    );
  }

  // Lưu danh sách thiết bị vào SharedPreferences
  static Future<void> saveDevices(List<Device> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceList = devices.map((device) => device.toJson()).toList();
    await prefs.setString('devices', jsonEncode(deviceList));
  }

  // Đọc danh sách thiết bị từ SharedPreferences
  static Future<List<Device>> getDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceString = prefs.getString('devices');
    if (deviceString == null) return [];

    final deviceList = jsonDecode(deviceString) as List;
    return deviceList.map((json) => Device.fromJson(json)).toList();
  }
}
