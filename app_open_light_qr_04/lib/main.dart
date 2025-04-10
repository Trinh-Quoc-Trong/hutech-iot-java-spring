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
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
        ),
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
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      setState(() {
        receivedMessage = message;
        // Cập nhật trạng thái bóng đèn dựa trên message nhận được
        if (message == "1") {
          isBulbOn = true;
        } else if (message == "0") {
          isBulbOn = false;
        }
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
    client.publishMessage(
        '/test/topic1', MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Bulb Control'),
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        shadowColor: Colors.black54,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: _toggleBulb,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isBulbOn ? Colors.yellowAccent : Colors.grey,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    isBulbOn ? 'assets/bulb_on.png' : 'assets/bulb_off.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Received Message:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                receivedMessage,
                style: Theme.of(context).textTheme.bodyMedium,
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
