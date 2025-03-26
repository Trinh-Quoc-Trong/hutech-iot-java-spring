import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String broker = '192.168.164.228';
  final int port = 1883;
  final String topic = '/test/topic1';
  late MqttServerClient client;
  bool isLedOn = false; // Trạng thái mặc định của đèn

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    client = MqttServerClient(broker, 'flutter_client');
    client.port = port;
    client.keepAlivePeriod = 60;
    client.logging(on: false);
    client.onConnected = () {
      print('✅ Kết nối MQTT thành công!');
      _listenToMqtt(); // Lắng nghe MQTT khi kết nối thành công
    };
    client.onDisconnected = () => print('❌ Mất kết nối MQTT!');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Lỗi kết nối MQTT: $e');
      client.disconnect();
    }
  }

  // 🔥 Hàm lắng nghe dữ liệu từ MQTT
  void _listenToMqtt() {
    client.subscribe(topic, MqttQos.atMostOnce);
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMess =
          messages[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print("📥 Nhận dữ liệu từ MQTT: $payload");

      setState(() {
        isLedOn = payload.trim() == "1";
      });
    });
  }

  void _toggleLed() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(isLedOn ? "0" : "1"); // Đảo trạng thái đèn
      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
      print("📢 Gửi tín hiệu: ${isLedOn ? "Tắt" : "Bật"}");
    } else {
      print("⚠️ Chưa kết nối MQTT!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Điều khiển Đèn MQTT')),
        body: Center(
          child: ElevatedButton(
            onPressed: _toggleLed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLedOn ? Colors.green : Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              isLedOn ? 'Bật' : 'Tắt',
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
