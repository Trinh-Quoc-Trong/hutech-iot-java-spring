import 'dart:async';
import 'package:flutter/material.dart';
import 'device_card.dart'; // Import DeviceCard
import 'package:mqtt_client/mqtt_client.dart'; // Thêm import MQTT client
import 'package:mqtt_client/mqtt_server_client.dart'; // Thêm import MQTT server client
import 'dart:convert'; // Thêm import để sử dụng jsonDecode
import 'package:mobile_scanner/mobile_scanner.dart'; // Import QR Scanner

// Dữ liệu mẫu cho thiết bị
class DeviceInfo {
  final String id; // ID duy nhất, có thể dùng topic hoặc kết hợp broker+topic
  final String name; // Tên có thể chỉnh sửa sau này
  final IconData icon;
  bool isOn;
  final String broker;
  final int port;
  final String topic;
  String clientIdentifier; // Client ID cho kết nối MQTT

  DeviceInfo({
    required this.id,
    required this.name,
    this.icon = Icons.lightbulb_outline, // Icon mặc định
    required this.broker,
    required this.port,
    required this.topic,
    this.isOn = false,
  }) : clientIdentifier =
            'flutter_${id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}'; // Tạo client ID duy nhất

  // --- Thêm phương thức toJson/fromJson để lưu trữ (ví dụ) ---
  // Bạn cần import 'dart:convert'; nếu dùng jsonEncode/Decode ở nơi khác
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon.codePoint, // Lưu code point của icon
        'isOn': isOn,
        'broker': broker,
        'port': port,
        'topic': topic,
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        id: json['id'],
        name: json['name'],
        icon: IconData(json['icon'],
            fontFamily: 'MaterialIcons'), // Tái tạo IconData
        isOn: json['isOn'],
        broker: json['broker'],
        port: json['port'],
        topic: json['topic'],
      );
}

// Widget hiển thị danh sách thiết bị của một phòng
class RoomDevicesView extends StatefulWidget {
  final String roomName;
  final List<DeviceInfo> devices;
  // Thêm callback để gửi lệnh MQTT
  final Function(String topic, String message) publishMessage;

  const RoomDevicesView({
    super.key,
    required this.roomName,
    required this.devices,
    required this.publishMessage, // Thêm callback vào constructor
  });

  @override
  State<RoomDevicesView> createState() => _RoomDevicesViewState();
}

class _RoomDevicesViewState extends State<RoomDevicesView> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0), // Thêm padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Số cột
        crossAxisSpacing: 16.0, // Khoảng cách ngang
        mainAxisSpacing: 16.0, // Khoảng cách dọc
        childAspectRatio: 1.0, // Tỷ lệ thẻ (width / height)
      ),
      itemCount: widget.devices.length,
      itemBuilder: (context, index) {
        final device = widget.devices[index];
        return DeviceCard(
          deviceName: device.name,
          iconData: device.icon,
          initialStatus: device.isOn,
          onStatusChanged: (bool status) {
            // Gửi lệnh MQTT khi trạng thái thay đổi
            final message = status ? '1' : '0';
            widget.publishMessage(device.topic, message);
            // Không cần setState ở đây nữa vì UI sẽ cập nhật khi nhận lại message từ MQTT
          },
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DeviceInfo> allDevices = []; // Danh sách thiết bị động
  // Map quản lý các MQTT client, key là "broker:port"
  final Map<String, MqttServerClient> _mqttClients = {};
  // Map quản lý các subscription của từng client để tránh trùng lặp
  final Map<String, Set<String>> _clientSubscriptions = {};
  // Map quản lý stream subscription để hủy khi disconnect
  final Map<String, StreamSubscription> _clientUpdateSubscriptions = {};

  MobileScannerController scannerController = MobileScannerController();
  bool _isScanning = false; // Để kiểm soát trạng thái màn hình quét

  @override
  void initState() {
    super.initState();

    // --- Thêm thiết bị mặc định ---
    final defaultDevice = DeviceInfo(
      id: "default_192.168.100.40:1883_/test/topic1", // Tạo ID duy nhất
      name: "Đèn Mặc Định", // Tên ví dụ
      broker: "192.168.100.40",
      port: 1883,
      topic: "/test/topic1",
      // icon: Icons.lightbulb, // Có thể chọn icon khác nếu muốn
    );
    allDevices.add(defaultDevice);
    // --- Kết thúc thêm thiết bị mặc định ---

    // TODO: Load saved devices from storage (e.g., SharedPreferences) here
    // Nếu có load từ storage, bạn nên kiểm tra nếu allDevices rỗng sau khi load
    // thì mới thêm defaultDevice.

    // Kết nối MQTT cho các thiết bị ban đầu (bao gồm thiết bị mặc định)
    // Sử dụng Future.forEach để tránh lỗi nếu list rỗng và xử lý bất đồng bộ
    Future.forEach(allDevices, (device) async {
      await _connectAndSubscribeDevice(device);
    });
  }

  // --- Hàm kết nối và đăng ký cho một thiết bị ---
  Future<void> _connectAndSubscribeDevice(DeviceInfo device) async {
    final clientKey = "${device.broker}:${device.port}";
    MqttServerClient client;

    // 1. Lấy hoặc tạo MQTT Client
    if (_mqttClients.containsKey(clientKey)) {
      client = _mqttClients[clientKey]!;
      print('Reusing MQTT client for $clientKey');
    } else {
      print(
          'Creating new MQTT client for $clientKey with ID: ${device.clientIdentifier}');
      client = MqttServerClient(device.broker, device.clientIdentifier);
      client.port = device.port;
      client.keepAlivePeriod = 20;
      client.logging(on: false); // Tắt bớt log mặc định
      client.onConnected = () => _onConnected(clientKey);
      client.onDisconnected = () => _onDisconnected(clientKey);
      client.onSubscribed = (topic) => _onSubscribed(clientKey, topic);
      client.pongCallback =
          () => print('Ping response received for $clientKey');

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(device.clientIdentifier)
          // .authenticateAs('username', 'password') // Thêm nếu cần xác thực
          .startClean() // Clean session
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMessage;

      _mqttClients[clientKey] = client;
      _clientSubscriptions[clientKey] = {}; // Khởi tạo set topic cho client mới
      // Hủy subscription cũ nếu có trước khi tạo mới
      _clientUpdateSubscriptions[clientKey]?.cancel();

      // --- Sửa lỗi Null check operator ---
      // Kiểm tra xem stream updates có null không trước khi lắng nghe
      if (client.updates != null) {
        _clientUpdateSubscriptions[clientKey] = client.updates!
            .listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
          _handleMqttMessage(c, clientKey);
        });
      } else {
        // Ghi log hoặc xử lý trường hợp stream updates bị null (hiếm gặp)
        print(
            'Error: MQTT client updates stream is null for $clientKey even after client creation.');
      }
      // --- Kết thúc sửa lỗi ---

      try {
        print('MQTT Client [$clientKey] Connecting....');
        await client.connect();
      } catch (e) {
        print('MQTT Client [$clientKey] Exception: $e');
        client.disconnect();
        _mqttClients.remove(clientKey); // Xóa client nếu kết nối lỗi
        _clientSubscriptions.remove(clientKey);
        _clientUpdateSubscriptions.remove(clientKey);
        // Có thể hiển thị lỗi cho người dùng
        return; // Dừng lại nếu không kết nối được
      }
    }

    // 2. Đăng ký Topic (nếu chưa đăng ký cho client này)
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      if (!_clientSubscriptions[clientKey]!.contains(device.topic)) {
        print('MQTT Client [$clientKey] Subscribing to: ${device.topic}');
        client.subscribe(device.topic, MqttQos.atLeastOnce);
        // Không cần đợi onSubscribed ở đây, nhưng thêm vào set để theo dõi
        _clientSubscriptions[clientKey]!.add(device.topic);
      } else {
        print(
            'MQTT Client [$clientKey] Already subscribed to: ${device.topic}');
      }
    } else {
      print('MQTT Client [$clientKey] Not connected. Cannot subscribe.');
      // Có thể thử kết nối lại ở đây hoặc đợi onConnected
    }
  }

  // --- Xử lý tin nhắn MQTT đến ---
  void _handleMqttMessage(
      List<MqttReceivedMessage<MqttMessage?>>? c, String clientKey) {
    if (c == null || c.isEmpty || c[0].payload == null) return;

    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String topic = c[0].topic;
    final String message =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    print('[$clientKey] Received message: $message from topic: $topic');

    // Cập nhật trạng thái thiết bị khớp với topic VÀ broker/port (thông qua clientKey)
    final affectedDeviceIndex = allDevices.indexWhere(
        (d) => d.topic == topic && "${d.broker}:${d.port}" == clientKey);

    if (affectedDeviceIndex != -1) {
      setState(() {
        allDevices[affectedDeviceIndex].isOn = (message == '1');
        print(
            'Device ${allDevices[affectedDeviceIndex].name} state updated to ${allDevices[affectedDeviceIndex].isOn}');
      });
    } else {
      print('No device found for topic $topic on client $clientKey');
    }
  }

  // --- Callbacks MQTT ---
  void _onConnected(String clientKey) {
    print('MQTT Client [$clientKey] Connected');
    // Re-subscribe các topic cần thiết cho client này khi kết nối lại
    final topicsToSubscribe = allDevices
        .where((d) => "${d.broker}:${d.port}" == clientKey)
        .map((d) => d.topic)
        .toSet(); // Dùng Set để tránh trùng lặp

    final client = _mqttClients[clientKey];
    if (client != null &&
        client.connectionStatus?.state == MqttConnectionState.connected) {
      // Xóa các sub cũ của client này để đảm bảo sạch sẽ
      _clientSubscriptions[clientKey]?.clear();
      topicsToSubscribe.forEach((topic) {
        if (!_clientSubscriptions[clientKey]!.contains(topic)) {
          print(
              'MQTT Client [$clientKey] Subscribing to: $topic on (re)connect');
          client.subscribe(topic, MqttQos.atLeastOnce);
          _clientSubscriptions[clientKey]!.add(topic);
        }
      });
    }
  }

  void _onDisconnected(String clientKey) {
    print('MQTT Client [$clientKey] Disconnected');
    // Xóa client khỏi map khi disconnect để lần sau tạo lại kết nối mới
    // Hoặc có thể thêm logic tự động kết nối lại ở đây
    _clientUpdateSubscriptions[clientKey]?.cancel(); // Hủy stream listener
    _mqttClients.remove(clientKey);
    _clientSubscriptions.remove(clientKey);
    _clientUpdateSubscriptions.remove(clientKey);
    // Cập nhật UI nếu cần (ví dụ: hiển thị trạng thái mất kết nối cho thiết bị)
    setState(() {}); // Cập nhật để có thể hiện thị lỗi nếu cần
  }

  void _onSubscribed(String clientKey, String topic) {
    print('MQTT Client [$clientKey] Subscribed to $topic');
    // Có thể thêm vào set ở đây thay vì lúc gọi subscribe
    // _clientSubscriptions[clientKey]?.add(topic);
  }

  // --- Hàm gửi message MQTT ---
  void _publishMessage(DeviceInfo device, String message) {
    final clientKey = "${device.broker}:${device.port}";
    if (_mqttClients.containsKey(clientKey)) {
      final client = _mqttClients[clientKey]!;
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        client.publishMessage(
            device.topic, MqttQos.atLeastOnce, builder.payload!);
        print(
            '[$clientKey] Published message: $message to topic: ${device.topic}');
      } else {
        print('MQTT Client [$clientKey] not connected, cannot publish.');
        // Thử kết nối lại client này?
        _connectAndSubscribeDevice(device);
      }
    } else {
      print('No MQTT client found for $clientKey. Attempting to connect.');
      // Nếu chưa có client, thử kết nối và gửi lại? (Cần cẩn thận tránh vòng lặp)
      _connectAndSubscribeDevice(device).then((_) {
        // Thử gửi lại sau khi kết nối (có thể cần đợi 1 chút)
        Future.delayed(const Duration(seconds: 1), () {
          if (_mqttClients[clientKey]?.connectionStatus?.state ==
              MqttConnectionState.connected) {
            final builder = MqttClientPayloadBuilder();
            builder.addString(message);
            _mqttClients[clientKey]!.publishMessage(
                device.topic, MqttQos.atLeastOnce, builder.payload!);
            print(
                '[$clientKey] Published message (after reconnect): $message to topic: ${device.topic}');
          }
        });
      });
    }
  }

  // --- Hàm xử lý dữ liệu QR Code ---
  void _handleQrCode(String rawValue) {
    print("Raw QR value: $rawValue");
    // Định dạng mong đợi: @mqtt://<broker>,<port>,<topic>
    final RegExp mqttPattern = RegExp(r'^@mqtt://([^,]+),(\d+),(.+)$');
    final match = mqttPattern.firstMatch(rawValue);

    if (match != null) {
      final broker = match.group(1)!;
      final port =
          int.tryParse(match.group(2)!) ?? 1883; // Mặc định port 1883 nếu lỗi
      final topic = match.group(3)!;

      print("Parsed: broker=$broker, port=$port, topic=$topic");

      // Kiểm tra xem thiết bị đã tồn tại chưa (dựa trên ID hoặc broker+topic)
      final deviceId = "$broker:$port/$topic"; // Tạo ID tạm
      if (allDevices.any((d) => d.id == deviceId)) {
        print("Device already exists: $deviceId");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị này đã được thêm.')),
        );
        return;
      }

      // Tạo và thêm thiết bị mới
      final newDevice = DeviceInfo(
        id: deviceId,
        name: "Thiết bị mới (${topic.split('/').last})", // Tên tạm
        broker: broker,
        port: port,
        topic: topic,
      );

      setState(() {
        allDevices.add(newDevice);
      });

      // Kết nối MQTT cho thiết bị mới
      _connectAndSubscribeDevice(newDevice);

      // TODO: Lưu danh sách allDevices vào storage

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm: ${newDevice.name}')),
      );
    } else {
      print("Invalid QR code format.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Định dạng mã QR không hợp lệ.')),
      );
    }
  }

  @override
  void dispose() {
    // Ngắt kết nối tất cả các client MQTT
    _clientUpdateSubscriptions.forEach((key, sub) => sub.cancel());
    _mqttClients.forEach((key, client) {
      client.disconnect();
      print("MQTT Client [$key] disconnected in dispose");
    });
    scannerController.dispose(); // Dispose QR Scanner controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Màn hình quét QR ---
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quét mã QR thiết bị'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _isScanning = false),
          ),
        ),
        body: MobileScanner(
          controller: scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
              final String code = barcodes.first.rawValue!;
              // Dừng quét và xử lý mã
              scannerController.stop();
              setState(() {
                _isScanning = false;
              });
              _handleQrCode(code);
            }
          },
        ),
      );
    }

    // --- Màn hình chính hiển thị danh sách thiết bị ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home (Dynamic Devices)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Thêm thiết bị mới',
            onPressed: () => setState(() => _isScanning = true),
          ),
        ],
      ),
      body: Container(
        // Thêm gradient hoặc màu nền nếu muốn
        child: allDevices.isEmpty
            ? const Center(
                child: Text('Chưa có thiết bị nào.\nNhấn nút quét QR để thêm.',
                    textAlign: TextAlign.center),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: allDevices.length,
                itemBuilder: (context, index) {
                  final device = allDevices[index];
                  // Kiểm tra trạng thái kết nối của client tương ứng
                  final clientKey = "${device.broker}:${device.port}";
                  final bool isConnected =
                      _mqttClients.containsKey(clientKey) &&
                          _mqttClients[clientKey]?.connectionStatus?.state ==
                              MqttConnectionState.connected;

                  // TODO: Có thể truyền trạng thái isConnected xuống DeviceCard để hiển thị
                  return Opacity(
                    // Làm mờ nếu không kết nối được
                    opacity: isConnected ? 1.0 : 0.6,
                    child: DeviceCard(
                      key: ValueKey(device
                          .id), // Key quan trọng để Flutter nhận diện đúng widget
                      deviceName: device.name,
                      iconData: device.icon,
                      initialStatus: device.isOn,
                      onStatusChanged: (bool status) {
                        // Gửi lệnh MQTT khi trạng thái thay đổi
                        final message = status ? '1' : '0';
                        _publishMessage(device, message);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
