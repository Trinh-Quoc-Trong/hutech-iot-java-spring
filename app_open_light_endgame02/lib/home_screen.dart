import 'package:flutter/material.dart';
import 'device_card.dart'; // Import DeviceCard

// Dữ liệu mẫu cho thiết bị
class DeviceInfo {
  final String name;
  final IconData icon;
  bool isOn;

  DeviceInfo({required this.name, required this.icon, this.isOn = false});
}

// Widget hiển thị danh sách thiết bị của một phòng
class RoomDevicesView extends StatefulWidget {
  final String roomName;
  final List<DeviceInfo> devices;

  const RoomDevicesView({
    super.key,
    required this.roomName,
    required this.devices,
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
            // Cập nhật trạng thái (trong ứng dụng thực tế sẽ gọi API)
            setState(() {
              device.isOn = status;
            });
            print(
                '${device.name} in ${widget.roomName} is now ${status ? "ON" : "OFF"}');
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dữ liệu mẫu
  final List<DeviceInfo> livingRoomDevices = [
    DeviceInfo(name: 'Đèn trần', icon: Icons.lightbulb_outline, isOn: true),
    DeviceInfo(name: 'Quạt', icon: Icons.wind_power_outlined),
    DeviceInfo(name: 'TV', icon: Icons.tv_outlined, isOn: false),
    DeviceInfo(name: 'Đèn bàn', icon: Icons.light_outlined),
  ];

  final List<DeviceInfo> kitchenDevices = [
    DeviceInfo(name: 'Đèn bếp', icon: Icons.lightbulb_outline),
    DeviceInfo(name: 'Tủ lạnh', icon: Icons.kitchen_outlined, isOn: true),
    DeviceInfo(name: 'Lò vi sóng', icon: Icons.microwave_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home Control'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Phòng Khách'),
            Tab(text: 'Phòng Bếp'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.background, // Bắt đầu bằng màu nền chính
              colorScheme.tertiary
                  .withOpacity(0.3), // Chuyển nhẹ sang màu accent
              colorScheme.secondary
                  .withOpacity(0.2), // Kết thúc bằng màu secondary nhạt
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            RoomDevicesView(
                roomName: 'Phòng Khách', devices: livingRoomDevices),
            RoomDevicesView(roomName: 'Phòng Bếp', devices: kitchenDevices),
          ],
        ),
      ),
    );
  }
}
