import 'package:flutter/material.dart';

class DeviceCard extends StatefulWidget {
  final String deviceName;
  final IconData iconData;
  final bool initialStatus;
  final ValueChanged<bool> onStatusChanged;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.iconData,
    required this.initialStatus,
    required this.onStatusChanged,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  late bool isSwitchedOn;

  @override
  void initState() {
    super.initState();
    isSwitchedOn = widget.initialStatus;
  }

  @override
  void didUpdateWidget(DeviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus) {
      setState(() {
        isSwitchedOn = widget.initialStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Màu sắc và Gradient dựa trên trạng thái và Theme
    final List<Color> gradientColors = isSwitchedOn
        ? [
            colorScheme.primary,
            colorScheme.secondary
          ] // Xanh biển gradient khi bật
        : [
            colorScheme.surface,
            Colors.grey.shade200
          ]; // Màu nền thẻ và xám nhạt khi tắt

    final Color iconColor = isSwitchedOn
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withOpacity(0.6);
    final Color textColor =
        isSwitchedOn ? colorScheme.onPrimary : colorScheme.onSurface;

    return Card(
      // Sử dụng CardTheme đã định nghĩa trong main.dart
      // elevation, shape, color sẽ được lấy từ theme
      clipBehavior: Clip.antiAlias, // Để gradient không tràn ra ngoài bo góc
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          // Không cần borderRadius ở đây vì Card đã có shape
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.iconData,
              size: 40,
              color: iconColor,
            ),
            const SizedBox(height: 10),
            Text(
              widget.deviceName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2, // Giới hạn 2 dòng
              overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu quá dài
            ),
            // Switch giờ sẽ tự lấy style từ SwitchTheme trong main.dart
            Switch(
              value: isSwitchedOn,
              onChanged: (value) {
                setState(() {
                  isSwitchedOn = value;
                });
                widget.onStatusChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
