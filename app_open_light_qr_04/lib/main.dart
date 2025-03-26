import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Bulb Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MqttBulbControl(),
    );
  }
}

class MqttBulbControl extends StatefulWidget {
  const MqttBulbControl({super.key});

  @override
  _MqttBulbControlState createState() => _MqttBulbControlState();
}

class _MqttBulbControlState extends State<MqttBulbControl> {
  late MqttServerClient client;
  bool isBulbOn = false;
  String receivedMessage = 'No message received';

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
  }

  void _connectToMqtt() async {
    client = MqttServerClient('192.168.100.40', 'flutter_client');
    client.port = 1883;
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      setState(() {
        receivedMessage = message;
      });
    });
  }

  void _onConnected() {
    print('Connected to MQTT');
    client.subscribe('/test/topic1', MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('Disconnected from MQTT');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _toggleBulb() {
    setState(() {
      isBulbOn = !isBulbOn;
    });
    final message = isBulbOn ? '1' : '0';
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage('/test/topic1', MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Bulb Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: _toggleBulb,
              child: Image.asset(
                isBulbOn ? 'assets/bulb_on.png' : 'assets/bulb_off.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Received Message: $receivedMessage',
              style: const TextStyle(fontSize: 18),
            ),
          ],
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