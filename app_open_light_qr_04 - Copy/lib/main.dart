import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  String brokerUri = '';
  String topic = '';
  bool isScanning = false;

  void _connectToMqtt() async {
    if (brokerUri.isEmpty || topic.isEmpty) {
      setState(() {
        receivedMessage = 'Broker URI or Topic is empty';
      });
      return;
    }

    client = MqttServerClient(brokerUri, 'flutter_client');
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
      setState(() {
        receivedMessage = 'Failed to connect to MQTT broker';
      });
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
    setState(() {
      receivedMessage = 'Connected to MQTT broker';
    });
    client.subscribe(topic, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    setState(() {
      receivedMessage = 'Disconnected from MQTT broker';
    });
  }

  void _onSubscribed(String topic) {
    setState(() {
      receivedMessage = 'Subscribed to $topic';
    });
  }

  void _toggleBulb() {
    setState(() {
      isBulbOn = !isBulbOn;
    });
    final message = isBulbOn ? '1' : '0';
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _startScan() {
    setState(() {
      isScanning = true;
    });
  }

  void _handleBarcode(String barcode) {
    final parts = barcode.split(',');
    if (parts.length == 2) {
      setState(() {
        brokerUri = parts[0];
        topic = parts[1];
        isScanning = false;
      });
      _connectToMqtt();
    } else {
      setState(() {
        receivedMessage = 'Invalid QR code format';
        isScanning = false;
      });
    }
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
            if (isScanning)
              Expanded(
                child: MobileScanner(
                  onDetect: (barcode) {
                    if (barcode.barcodes.isNotEmpty) {
                      _handleBarcode(barcode.barcodes.first.rawValue!);
                    }
                  },
                ),
              )
            else
              Column(
                children: [
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startScan,
                    child: const Text('Scan QR Code'),
                  ),
                ],
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