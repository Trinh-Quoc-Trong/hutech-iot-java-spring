import 'package:flutter/material.dart';
import 'package:app_open_light_endgame01/services/voice_service.dart';

class VoiceControlScreen extends StatefulWidget {
  const VoiceControlScreen({Key? key}) : super(key: key);

  @override
  State<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends State<VoiceControlScreen> {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _lastCommand = '';
  List<String> _commandHistory = [];

  @override
  void initState() {
    super.initState();
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    _voiceService.onCommandRecognized = (command) {
      setState(() {
        _lastCommand = command;
        _commandHistory.insert(0, command);
        if (_commandHistory.length > 10) {
          _commandHistory.removeLast();
        }
      });

      // Xử lý lệnh giọng nói ở đây
      if (command == 'on') {
        _showMessage('Đã bật thiết bị');
      } else if (command == 'off') {
        _showMessage('Đã tắt thiết bị');
      }
    };

    _voiceService.onError = (error) {
      _showMessage('Lỗi: $error');
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleVoiceRecognition() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      await _voiceService.startListening();
      setState(() {
        _isListening = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khiển bằng giọng nói'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 100,
                    color: _isListening ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isListening ? 'Đang lắng nghe...' : 'Nhấn để bắt đầu',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lệnh cuối cùng: $_lastCommand',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch sử lệnh:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _commandHistory.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(_commandHistory[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleVoiceRecognition,
        backgroundColor: _isListening ? Colors.red : null,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
