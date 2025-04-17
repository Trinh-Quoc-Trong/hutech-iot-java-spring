import 'dart:async';
import 'dart:convert'; // Thêm import để sử dụng jsonDecode
import 'package:flutter/material.dart';
import 'device_card.dart'; // Import DeviceCard
import 'package:mqtt_client/mqtt_client.dart'; // Thêm import MQTT client
import 'package:mqtt_client/mqtt_server_client.dart'; // Thêm import MQTT server client
// Thêm import để sử dụng jsonDecode
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
    // Kiểm tra nếu danh sách thiết bị rỗng
    if (widget.devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Tăng padding
          child: Column(
            // Sử dụng Column để xếp icon và text
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.devices_other_outlined, // Icon gợi ý về thiết bị
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Không có thiết bị nào', // Thông báo ngắn gọn
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Quét mã QR để thêm thiết bị mới.', // Hướng dẫn rõ ràng hơn
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    // Giữ nguyên GridView nếu có thiết bị
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
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
            final message = status ? '1' : '0';
            widget.publishMessage(device.topic, message);
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
  int _selectedIndex = 0; // Chỉ số của mục đang được chọn trong BottomNavBar
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
    );
    // Kiểm tra xem thiết bị đã tồn tại chưa trước khi thêm
    if (!allDevices.any((d) => d.id == defaultDevice.id)) {
      allDevices.add(defaultDevice);
    }
    // --- Kết thúc thêm thiết bị mặc định ---

    // TODO: Load saved devices from storage

    // Kết nối MQTT cho các thiết bị ban đầu
    Future.forEach(allDevices, (device) async {
      await _connectAndSubscribeDevice(device);
    });
  }

  @override
  void dispose() {
    // Hủy các timer và dừng lắng nghe/ngắt kết nối
    for (var client in _mqttClients.values) {
      client.disconnect();
    }
    for (var sub in _clientUpdateSubscriptions.values) {
      sub.cancel();
    }
    scannerController.dispose();
    super.dispose();
  }

  // --- Hàm kết nối và đăng ký MQTT (Giữ nguyên) ---
  Future<void> _connectAndSubscribeDevice(DeviceInfo device) async {
    final clientKey = "${device.broker}:${device.port}";
    MqttServerClient client;

    // 1. Lấy hoặc tạo MQTT Client
    if (_mqttClients.containsKey(clientKey)) {
      client = _mqttClients[clientKey]!;
      print('MQTT DEBUG [$clientKey]: Reusing existing client.');
      // Kiểm tra lại trạng thái kết nối của client cũ
      if (client.connectionStatus?.state != MqttConnectionState.connected &&
          client.connectionStatus?.state != MqttConnectionState.connecting) {
        print(
            'MQTT DEBUG [$clientKey]: Existing client not connected, attempting to reconnect...');
        try {
          // Chỉ gọi connect nếu không phải đang kết nối rồi
          if (client.connectionStatus?.state !=
              MqttConnectionState.connecting) {
            await client.connect(); // Thử kết nối lại client cũ
          }
        } catch (e) {
          print('MQTT DEBUG [$clientKey]: Reconnect failed: $e');
          _handleConnectionError(clientKey);
          return;
        }
      }
    } else {
      print(
          'MQTT DEBUG [$clientKey]: Creating new client for ${device.clientIdentifier}');
      client = MqttServerClient.withPort(device.broker, device.clientIdentifier,
          device.port); // Sử dụng constructor withPort
      client.keepAlivePeriod = 20;
      client.logging(on: false);
      client.onConnected = () => _onConnected(clientKey);
      client.onDisconnected = () => _onDisconnected(clientKey);
      client.onSubscribed = (topic) => _onSubscribed(clientKey, topic);
      client.pongCallback =
          () => print('MQTT DEBUG [$clientKey]: Pong received');
      client.autoReconnect = true; // Bật tự động kết nối lại

      client.onAutoReconnect = () {
        print('MQTT DEBUG [$clientKey]: Auto Reconnect initiated.');
        if (mounted) {
          setState(() {
            // Có thể cập nhật UI để báo đang kết nối lại
          });
        }
      };
      client.onAutoReconnected = () {
        print('MQTT DEBUG [$clientKey]: Auto Reconnected SUCCESSFULLY.');
        // Đăng ký lại các topic sau khi tự động kết nối lại thành công
        // Listener cũng sẽ được thiết lập lại trong _onConnected được gọi bởi autoReconnect
        // _resubscribeTopics(clientKey); // Không cần gọi ở đây nếu _onConnected xử lý cả sub và listen
        if (mounted) {
          setState(() {
            // Cập nhật UI báo đã kết nối lại
          });
        }
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(device.clientIdentifier)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      client.connectionMessage = connMessage;

      _mqttClients[clientKey] = client;
      _clientSubscriptions[clientKey] = {};
      // _clientUpdateSubscriptions[clientKey]?.cancel(); // Hủy sub cũ không cần thiết ở đây vì sẽ tạo mới trong onConnected

      // --- XÓA KHỐI LỆNH LẮNG NGHE STREAM Ở ĐÂY ---
      // print('MQTT DEBUG [$clientKey]: Setting up updates stream listener...');
      // if (client.updates != null) { ... } else { ... }

      try {
        print('MQTT DEBUG [$clientKey]: Attempting initial connect...');
        await client.connect();
      } catch (e) {
        print('MQTT ERROR [$clientKey]: Initial Connection Exception: $e');
        _handleConnectionError(clientKey); // Gọi hàm xử lý lỗi kết nối chung
        return;
      }
    }

    // 2. Đăng ký Topic (Nên thực hiện trong onConnected hoặc resubscribe)
    // Vẫn gọi ở đây để xử lý trường hợp client đã tồn tại và đang kết nối
    _subscribeToTopic(client, clientKey, device.topic);
  }

  // --- Hàm đăng ký một topic cụ thể ---
  void _subscribeToTopic(
      MqttServerClient client, String clientKey, String topic) {
    // Kiểm tra trạng thái kết nối trước khi sub
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      // Chỉ sub nếu chưa sub topic này trên client này
      if (!_clientSubscriptions.containsKey(clientKey) ||
          !_clientSubscriptions[clientKey]!.contains(topic)) {
        print('MQTT DEBUG [$clientKey]: Attempting to subscribe to: $topic');
        client.subscribe(topic, MqttQos.atLeastOnce);
        // Không thêm vào _clientSubscriptions ở đây, chờ onSubscribed callback
      } else {
        print(
            'MQTT DEBUG [$clientKey]: Already subscribed to: $topic (Skipping)');
      }
    } else {
      print(
          'MQTT DEBUG [$clientKey]: Client not connected. Cannot subscribe to $topic now. Will attempt on (re)connect.');
    }
  }

  // --- Hàm đăng ký lại tất cả các topic đã biết cho một client ---
  void _resubscribeTopics(String clientKey) {
    final client = _mqttClients[clientKey];
    // Lấy danh sách các topic mà client này NÊN quản lý (từ allDevices)
    final expectedTopics = allDevices
        .where((d) => "${d.broker}:${d.port}" == clientKey)
        .map((d) => d.topic)
        .toSet();

    if (client != null && expectedTopics.isNotEmpty) {
      print(
          'MQTT DEBUG [$clientKey]: Resubscribing topics after (re)connect: ${expectedTopics.join(', ')}');
      // Lấy danh sách topic hiện đang sub (nếu có)
      final currentSubs = _clientSubscriptions[clientKey] ?? {};

      // Sub các topic cần thiết mà chưa sub
      expectedTopics.difference(currentSubs).forEach((topic) {
        _subscribeToTopic(client, clientKey, topic);
      });

      // (Optional) Unsubscribe các topic không cần thiết nữa (nếu logic yêu cầu)
      // currentSubs.difference(expectedTopics).forEach((topic) {
      //   print('MQTT DEBUG [$clientKey]: Unsubscribing from obsolete topic: $topic');
      //   client.unsubscribe(topic);
      //    _clientSubscriptions[clientKey]?.remove(topic);
      // });
    } else if (client != null && expectedTopics.isEmpty) {
      print(
          'MQTT DEBUG [$clientKey]: No topics to resubscribe for this client.');
    }
  }

  // --- Hàm xử lý lỗi kết nối MQTT ---
  void _handleConnectionError(String clientKey) {
    print('MQTT ERROR [$clientKey]: Handling connection error.');
    final client = _mqttClients[clientKey];
    client?.disconnect(); // Thử ngắt kết nối client nếu còn tồn tại

    // Dọn dẹp tài nguyên liên quan đến client này
    _mqttClients.remove(clientKey);
    _clientSubscriptions.remove(clientKey); // Xóa danh sách sub của client lỗi
    _clientUpdateSubscriptions[clientKey]?.cancel(); // Hủy stream listener
    _clientUpdateSubscriptions.remove(clientKey);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Mất kết nối MQTT tới $clientKey. Đang thử kết nối lại...')));
      setState(() {
        // Đánh dấu các thiết bị dùng client này là offline hoặc đang cố gắng kết nối lại
        allDevices
            .where((d) => "${d.broker}:${d.port}" == clientKey)
            .forEach((d) {
          print(
              "Device ${d.name} potentially offline due to connection error.");
          // Ví dụ: d.isConnecting = true; d.isOnline = false; (nếu có các thuộc tính này)
        });
      });
      // Cân nhắc: Lên lịch thử kết nối lại cho các thiết bị của client này sau một khoảng thời gian
      _scheduleReconnectForClient(clientKey);
    }
  }

  // --- Hàm lên lịch kết nối lại cho các thiết bị của một client bị lỗi ---
  void _scheduleReconnectForClient(String clientKey) {
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      print("Attempting scheduled reconnect for devices on $clientKey");
      final devicesToReconnect =
          allDevices.where((d) => "${d.broker}:${d.port}" == clientKey);
      Future.forEach(devicesToReconnect, (device) async {
        // Chỉ kết nối nếu client chưa tồn tại (đã bị xóa trong _handleConnectionError)
        if (!_mqttClients.containsKey(clientKey)) {
          print("Re-initiating connection for ${device.name} on $clientKey");
          await _connectAndSubscribeDevice(device);
        }
      });
    });
  }

  // --- Callbacks MQTT ---
  void _onConnected(String clientKey) {
    print('MQTT SUCCESS [$clientKey]: _onConnected callback triggered.');
    final client = _mqttClients[clientKey];

    // --- THÊM KHỐI LỆNH LẮNG NGHE STREAM Ở ĐÂY ---
    // Chỉ thiết lập listener nếu client tồn tại và chưa có listener nào cho client key này
    if (client != null && _clientUpdateSubscriptions[clientKey] == null) {
      print(
          'MQTT DEBUG [$clientKey]: Setting up updates stream listener inside onConnected.');
      if (client.updates != null) {
        _clientUpdateSubscriptions[clientKey] = client.updates!.listen(
            (List<MqttReceivedMessage<MqttMessage?>>? c) {
          _handleMqttMessage(c, clientKey);
        }, onError: (error) {
          print('MQTT ERROR [$clientKey]: Updates stream error: $error');
          _handleConnectionError(clientKey);
        }, onDone: () {
          print('MQTT DEBUG [$clientKey]: Updates stream closed.');
          // Xử lý khi stream đóng (có thể là do disconnect)
          // Không gọi _onDisconnected trực tiếp ở đây để tránh vòng lặp nếu disconnect gây ra onDone
          _clientUpdateSubscriptions.remove(clientKey); // Xóa sub đã đóng
          if (mounted) {
            setState(() {/* Có thể cập nhật UI báo listener đã dừng */});
          }
        });
        print(
            'MQTT DEBUG [$clientKey]: Updates stream listener set up successfully.');
      } else {
        print(
            'MQTT ERROR [$clientKey]: Updates stream is NULL even after connection!');
        // Xử lý lỗi nghiêm trọng này nếu xảy ra
      }
    } else if (client == null) {
      print(
          'MQTT ERROR [$clientKey]: Client is null in _onConnected. Cannot set up listener.');
    } else {
      print('MQTT DEBUG [$clientKey]: Updates stream listener already exists.');
    }
    // --- KẾT THÚC THÊM KHỐI LỆNH ---

    // Đảm bảo đăng ký lại các topic khi kết nối thủ công/tự động thành công
    _resubscribeTopics(clientKey);

    if (mounted) {
      setState(() {
        // Cập nhật UI báo kết nối thành công nếu cần
        allDevices
            .where((d) => "${d.broker}:${d.port}" == clientKey)
            .forEach((d) {
          // d.isConnecting = false; d.isOnline = true;
        });
      });
    }
  }

  void _onDisconnected(String clientKey) {
    print('MQTT DEBUG [$clientKey]: _onDisconnected callback triggered.');
    // Không xóa client ngay lập tức nếu bật autoReconnect
    if (!(_mqttClients[clientKey]?.autoReconnect ?? false)) {
      print(
          'MQTT DEBUG [$clientKey]: Client disconnected and autoReconnect is off. Cleaning up.');
      _handleConnectionError(
          clientKey); // Xử lý như lỗi kết nối nếu không tự kết nối lại
    } else {
      print(
          'MQTT DEBUG [$clientKey]: Client disconnected. AutoReconnect is on. Waiting...');
      if (mounted) {
        setState(() {
          // Cập nhật UI báo đang mất kết nối, chờ auto-reconnect
          allDevices
              .where((d) => "${d.broker}:${d.port}" == clientKey)
              .forEach((d) {
            // d.isConnecting = true; d.isOnline = false;
          });
        });
      }
    }
  }

  void _onSubscribed(String clientKey, String topic) {
    print(
        'MQTT SUCCESS [$clientKey]: Successfully subscribed to topic: $topic');
    // Thêm vào set sau khi đã sub thành công
    if (mounted) {
      setState(() {
        // Đảm bảo client key tồn tại trước khi thêm topic
        _clientSubscriptions.putIfAbsent(clientKey, () => {}).add(topic);
      });
    }
  }

  // --- Xử lý tin nhắn MQTT đến (Khôi phục kiểm tra trạng thái) ---
  void _handleMqttMessage(
      List<MqttReceivedMessage<MqttMessage?>>? c, String clientKey) {
    if (!mounted) return; // Kiểm tra mounted
    if (c == null || c.isEmpty || c[0].payload == null) return;

    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String topic = c[0].topic;
    final payload = recMess.payload.message;

    String message;
    try {
      message = MqttPublishPayload.bytesToStringAsString(payload);
    } catch (e) {
      print("Received non-UTF8 payload on topic $topic: ${payload.toString()}");
      return; // Bỏ qua nếu không xử lý được
    }

    print('[$clientKey] Received message: "$message" from topic: $topic');

    // Cập nhật trạng thái thiết bị
    final affectedDeviceIndex = allDevices.indexWhere(
        (d) => d.topic == topic && "${d.broker}:${d.port}" == clientKey);

    if (affectedDeviceIndex != -1) {
      bool newStatus = (message == '1');
      // Khôi phục lại kiểm tra trạng thái cũ
      if (allDevices[affectedDeviceIndex].isOn != newStatus) {
        setState(() {
          allDevices[affectedDeviceIndex].isOn = newStatus;
          print(
              'Device ${allDevices[affectedDeviceIndex].name} state updated to ${allDevices[affectedDeviceIndex].isOn}');
        });
      } else {
        // print('Device ${allDevices[affectedDeviceIndex].name} state already ${allDevices[affectedDeviceIndex].isOn}');
      }
    } else {
      print(
          'Received message for unknown device/topic combination: $topic on $clientKey');
    }
  }

  // --- Hàm gửi tin nhắn MQTT (Giữ nguyên) ---
  void _publishMessage(String topic, String message, String broker, int port) {
    final clientKey = "$broker:$port";
    if (_mqttClients.containsKey(clientKey)) {
      final client = _mqttClients[clientKey]!;
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        print(
            'MQTT Client [$clientKey] Publishing message: $message to topic: $topic');
        try {
          client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
        } catch (e) {
          print('MQTT ERROR [$clientKey]: Failed to publish message: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi gửi lệnh tới $clientKey: $e')));
          }
        }
      } else {
        print('MQTT Client [$clientKey] is not connected. Cannot publish.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Không thể gửi lệnh: Mất kết nối tới $clientKey')));
        }
        // Cân nhắc thử kết nối lại client này
        // _connectAndSubscribeDevice(...thiết bị tương ứng...);
      }
    } else {
      print('MQTT Client for $clientKey not found. Cannot publish.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Không thể gửi lệnh: Chưa kết nối tới $clientKey')));
      }
      // Cân nhắc thử tạo và kết nối client cho broker/port này nếu có thiết bị dùng nó
      // Sửa lỗi kiểu trả về của orElse bằng try-catch
      DeviceInfo? deviceForClient;
      try {
        deviceForClient =
            allDevices.firstWhere((d) => "${d.broker}:${d.port}" == clientKey);
      } catch (e) {
        deviceForClient = null; // Không tìm thấy
      }
      if (deviceForClient != null) {
        print("Attempting to connect client $clientKey before publishing.");
        _connectAndSubscribeDevice(deviceForClient); // Thử kết nối lại
      }
    }
  }

  // --- Xử lý sự kiện nhấn item trên BottomNavigationBar ---
  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        // Index 1 là nút "Thêm/Quét"
        _isScanning = true;
      } else {
        _isScanning = false;
      }
      // Xử lý cho index 2 (Cài đặt) nếu cần
      if (index == 2) {
        // Hiện tại chỉ hiển thị Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng cài đặt chưa được thêm.')));
        // Đặt lại selectedIndex về 0 (Home) sau khi hiển thị snackbar?
        _selectedIndex = 0; // Chuyển về Home ngay lập tức
      }
    });
  }

  // --- Hàm build UI (Đã cập nhật) ---
  @override
  Widget build(BuildContext context) {
    // Nhóm thiết bị theo phòng (ví dụ đơn giản: tất cả vào 1 phòng)
    final Map<String, List<DeviceInfo>> devicesByRoom = {
      'Phòng chính': allDevices,
      // Thêm các phòng khác nếu cần
    };
    final roomNames = devicesByRoom.keys.toList();

    // Widget chính sẽ là TabBarView hoặc ScannerView
    Widget currentView = _isScanning
        ? _buildScannerView()
        : DefaultTabController(
            length: roomNames.length,
            child: Column(
              // Sử dụng Column để đặt TabBar dưới AppBar một cách linh hoạt
              children: [
                // Thanh TabBar riêng biệt, có thể tạo kiểu dễ hơn
                Container(
                  color: Theme.of(context).appBarTheme.backgroundColor ??
                      Theme.of(context)
                          .colorScheme
                          .surface, // Màu nền khớp AppBar hoặc surface
                  child: TabBar(
                    isScrollable: roomNames.length > 3,
                    tabs: roomNames.map((name) => Tab(text: name)).toList(),
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withOpacity(0.7),
                    indicatorWeight: 3.0,
                    indicatorSize:
                        TabBarIndicatorSize.label, // Chỉ gạch chân dưới chữ
                  ),
                ),
                // Phần TabBarView chiếm phần còn lại
                Expanded(
                  child: TabBarView(
                    children: roomNames.map((roomName) {
                      final devicesInRoom = devicesByRoom[roomName] ?? [];
                      return RoomDevicesView(
                        roomName: roomName,
                        devices: devicesInRoom,
                        publishMessage: (topic, message) {
                          // Sửa lỗi kiểu trả về của orElse bằng try-catch
                          DeviceInfo? deviceInRoom;
                          try {
                            deviceInRoom = devicesInRoom
                                .firstWhere((dev) => dev.topic == topic);
                          } catch (e) {
                            deviceInRoom = null;
                          }

                          if (deviceInRoom != null) {
                            DeviceInfo? device;
                            try {
                              device = allDevices
                                  .firstWhere((d) => d.id == deviceInRoom!.id);
                            } catch (e) {
                              device = null;
                            }
                            if (device != null) {
                              _publishMessage(
                                  topic, message, device.broker, device.port);
                            } else {
                              print(
                                  "Error: Could not find device info in allDevices for topic $topic during manual publish.");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'Lỗi: Không tìm thấy thông tin thiết bị (allDevices) cho topic $topic')));
                              }
                            }
                          } else {
                            print(
                                "Error: Could not find device info in room '$roomName' for topic $topic during manual publish.");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      'Lỗi: Không tìm thấy thông tin thiết bị (room) cho topic $topic')));
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Điều khiển nhà'),
        backgroundColor:
            Theme.of(context).colorScheme.surface, // Nền trong suốt/đồng màu
        elevation: 0, // Bỏ shadow
        centerTitle: false, // Tiêu đề căn trái cho hiện đại hơn
        titleTextStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
        actions: [
          // Icon trạng thái kết nối MQTT tổng quát (ví dụ)
          // Bạn có thể làm phức tạp hơn để hiển thị trạng thái từng broker
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              _mqttClients.values.any((c) =>
                      c.connectionStatus?.state ==
                      MqttConnectionState.connected)
                  ? Icons.cloud_queue_rounded // Có ít nhất 1 kết nối
                  : Icons.cloud_off_rounded, // Mất tất cả kết nối
              color: _mqttClients.values.any((c) =>
                      c.connectionStatus?.state ==
                      MqttConnectionState.connected)
                  ? Colors.green // Màu xanh khi kết nối
                  : Colors.grey, // Màu xám khi mất kết nối
              size: 24,
            ),
          ),
          const SizedBox(width: 8), // Thêm khoảng trống nhỏ cuối AppBar
        ],
      ),
      body: currentView, // Hiển thị TabBarView hoặc Scanner
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled), // Icon filled cho mục đang chọn
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded), // Icon quét QR
            label: 'Thêm/Quét',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped, // Gọi hàm xử lý khi nhấn
        backgroundColor:
            Theme.of(context).colorScheme.surface, // Màu nền NavBar
        elevation: 8.0, // Thêm chút bóng đổ cho NavBar
        type: BottomNavigationBarType.fixed, // Giữ kích thước item cố định
        showUnselectedLabels: false, // Ẩn chữ của mục không chọn
      ),
    );
  }

  // --- Widget xây dựng màn hình quét QR ---
  Widget _buildScannerView() {
    return Scaffold(
      // AppBar riêng cho màn hình quét
      appBar: AppBar(
        title: const Text('Quét mã QR thiết bị'),
        backgroundColor:
            Theme.of(context).colorScheme.surface, // Có thể dùng màu khác
        elevation: 1, // Thêm chút shadow
        leading: IconButton(
          icon: const Icon(Icons.close_rounded), // Dùng icon X thay vì back
          tooltip: 'Đóng',
          onPressed: () {
            if (mounted) {
              scannerController.stop(); // Dừng camera trước
              setState(() {
                _isScanning = false; // Quay lại màn hình chính
                _selectedIndex = 0; // Đặt lại tab về Home
              });
            }
          },
        ),
      ),
      body: MobileScanner(
        controller: scannerController,
        // Fit ảnh vào khung nhìn
        fit: BoxFit.cover,
        // Cho phép zoom
        // controller: MobileScannerController(detectionSpeed: DetectionSpeed.normal, facing: CameraFacing.back, torchEnabled: false),
        onDetect: (capture) {
          if (!mounted) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? qrData = barcodes.first.rawValue;
            print('QR Code detected: $qrData');
            if (qrData != null) {
              // Dừng quét *trước* khi xử lý để tránh quét liên tục
              scannerController.stop();
              _handleScannedData(qrData); // Xử lý dữ liệu quét được
            }
            // Quay lại màn hình chính sau khi xử lý
            if (mounted) {
              setState(() {
                _isScanning = false;
                _selectedIndex = 0; // Đặt lại tab về Home
              });
            }
          }
        },
      ),
    );
  }

  // --- Hàm xử lý dữ liệu quét được từ QR (Sửa lỗi tên mặc định) ---
  void _handleScannedData(String data) {
    if (!mounted) return; // Kiểm tra mounted
    try {
      final parts = data.split(';');
      if (parts.length >= 3) {
        final broker = parts[0].trim();
        final port = int.tryParse(parts[1].trim());
        final topic = parts[2].trim();
        // Sửa lỗi lastOrDefault và tên mặc định
        final name = parts.length >= 4 && parts[3].trim().isNotEmpty
            ? parts[3].trim()
            : "Thiết bị (${topic.split('/').where((s) => s.isNotEmpty).lastOrNull ?? '?'})";

        if (port != null && broker.isNotEmpty && topic.isNotEmpty) {
          final newDeviceId = "$broker:$port:$topic";

          if (!allDevices.any((d) => d.id == newDeviceId)) {
            if (allDevices.any((d) =>
                d.broker == broker && d.port == port && d.topic == topic)) {
              print("Device with same broker/port/topic already exists.");
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Thiết bị với cùng topic đã tồn tại.')));
              return;
            }

            final newDevice = DeviceInfo(
              id: newDeviceId,
              name: name,
              broker: broker,
              port: port,
              topic: topic,
            );

            print("Adding new device: ${newDevice.name} ($newDeviceId)");

            if (mounted) {
              setState(() {
                allDevices.add(newDevice);
              });
            }
            _connectAndSubscribeDevice(newDevice);

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã thêm thiết bị: ${newDevice.name}')));
          } else {
            print("Device with ID $newDeviceId already exists.");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Thiết bị này đã được thêm trước đó.')));
          }
        } else {
          throw FormatException(
              "Thông tin broker, port, hoặc topic không hợp lệ hoặc bị thiếu.");
        }
      } else {
        throw FormatException(
            "Định dạng QR không đúng (cần broker;port;topic;[name])");
      }
    } catch (e) {
      print("Lỗi xử lý dữ liệu QR: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi đọc mã QR: $e')));
    }
  }
} // Kết thúc _HomeScreenState
