import 'package:flutter/material.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết bị của tôi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDeviceCard(
            context,
            'Đèn phòng khách',
            'Đang bật',
            Icons.lightbulb,
            Colors.amber,
          ),
          const SizedBox(height: 16),
          _buildDeviceCard(
            context,
            'Đèn phòng ngủ',
            'Đang tắt',
            Icons.lightbulb_outline,
            Colors.grey,
          ),
          const SizedBox(height: 16),
          _buildDeviceCard(
            context,
            'Quạt',
            'Đang bật',
            Icons.air,
            Colors.blue,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Thêm thiết bị mới
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    String name,
    String status,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(name),
        subtitle: Text(status),
        trailing: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Mở cài đặt thiết bị
          },
        ),
        onTap: () {
          // Mở chi tiết thiết bị
        },
      ),
    );
  }
}
