import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/device.dart';

class DeviceControlScreen extends StatefulWidget {
  final Device device;
  final String? initialCommand;

  const DeviceControlScreen({
    Key? key,
    required this.device,
    this.initialCommand,
  }) : super(key: key);

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  late MqttServerClient client;
  String receivedMessage = 'Chưa nhận tin nhắn';

  @override
  void initState() {
    super.initState();
    _connectToMqtt();
    if (widget.initialCommand != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processInitialCommand(widget.initialCommand!);
      });
    }
  }

  void _processInitialCommand(String command) {
    if (command == 'on' && !widget.device.isOn) {
      _toggleDevice();
    } else if (command == 'off' && widget.device.isOn) {
      _toggleDevice();
    }
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
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      setState(() {
        receivedMessage = message;
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
    client.subscribe(widget.device.topic, MqttQos.atLeastOnce);
  }

  void _onDisconnected() {
    print('Disconnected from MQTT');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: _toggleDevice,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.device.isOn ? Colors.yellow : Colors.grey,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    size: 80,
                    color: widget.device.isOn ? Colors.yellow : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Trạng thái:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.device.isOn ? 'Bật' : 'Tắt',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tin nhắn nhận được:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                receivedMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
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
