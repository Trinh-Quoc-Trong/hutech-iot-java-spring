import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/device.dart';

class QRScannerScreen extends StatefulWidget {
  final String roomName;

  const QRScannerScreen({Key? key, required this.roomName}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quét mã QR - ${widget.roomName}'),
        backgroundColor: Color(0xFFDB3022),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: MobileScanner(
              onDetect: (capture) {
                if (isProcessing) return;

                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    _processQRCode(code);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Đặt mã QR vào khung hình để quét',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processQRCode(String qrData) async {
    setState(() {
      isProcessing = true;
    });

    final parts = qrData.split(',');
    if (parts.length >= 3) {
      final broker = parts[0];
      final port = int.tryParse(parts[1]);
      final topic = parts[2];

      if (port != null) {
        // Tạo thiết bị mới
        final device = Device(
          id: const Uuid().v4(),
          name: 'Bóng đèn ${widget.roomName}',
          broker: broker,
          port: port,
          topic: topic,
          type: 'light',
        );

        // Lưu thiết bị
        final devices = await Device.getDevices();
        devices.add(device);
        await Device.saveDevices(devices);

        // Quay lại màn hình chính
        if (mounted) {
          Navigator.pop(context, device);
        }
      } else {
        _showError('Định dạng mã QR không hợp lệ');
      }
    } else {
      _showError('Định dạng mã QR không hợp lệ');
    }

    setState(() {
      isProcessing = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
