import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/device.dart';

class DeviceControlScreen extends StatefulWidget {
  final Device device;

  const DeviceControlScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceControlScreenState createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late MqttServerClient client;
  bool isConnected = false;
  String receivedMessage = 'Chưa nhận được tin nhắn';

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
  }

  void _connectToMqtt() async {
    client = MqttServerClient(
        widget.device.broker, 'flutter_client_${widget.device.id}');
    client.port = widget.device.port;
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${widget.device.id}')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      _showError('Không thể kết nối đến thiết bị');
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      setState(() {
        receivedMessage = message;
        // Cập nhật trạng thái thiết bị dựa trên message nhận được
        if (message == "1") {
          widget.device.isOn = true;
        } else if (message == "0") {
          widget.device.isOn = false;
        }
      });
    });
  }

  void _onConnected() {
    print('Connected to MQTT');
    setState(() {
      isConnected = true;
    });
    client.subscribe(widget.device.topic, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('Disconnected from MQTT');
    setState(() {
      isConnected = false;
    });
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _toggleDevice() {
    setState(() {
      widget.device.isOn = !widget.device.isOn;
    });
    final message = widget.device.isOn ? '1' : '0';
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(
        widget.device.topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Color(0xFFDB3022),
        elevation: 10,
        shadowColor: Colors.black54,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDB3022), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (!isConnected)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Đang kết nối...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              GestureDetector(
                onTap: isConnected ? _toggleDevice : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.device.isOn
                            ? Colors.yellowAccent
                            : Colors.grey,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.device.isOn
                        ? Icons.lightbulb
                        : Icons.lightbulb_outline,
                    size: 120,
                    color: widget.device.isOn ? Colors.yellow : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Trạng thái:',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                widget.device.isOn ? 'Bật' : 'Tắt',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'Tin nhắn nhận được:',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                receivedMessage,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}
