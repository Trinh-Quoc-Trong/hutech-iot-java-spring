import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  TextToSpeech() {
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.setLanguage('vi-VN');
    await _flutterTts.setSpeechRate(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (_isInitialized) {
      await _flutterTts.speak(text);
    }
  }
}

class VoiceService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final TextToSpeech _tts = TextToSpeech();
  bool _isInitialized = false;

  Function(String)? onCommandRecognized;
  Function(String)? onError;

  Future<void> _initSpeech() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Lỗi khởi tạo: $error');
          onError?.call(error.errorMsg);
        },
      );
      if (_isInitialized) {
        await _tts.speak('Đã khởi tạo nhận diện giọng nói thành công');
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo: $e');
      onError?.call(e.toString());
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      debugPrint('Đang khởi tạo nhận diện giọng nói...');
      await _initSpeech();
    }

    if (_isInitialized) {
      try {
        if (!await _speechToText.hasPermission) {
          debugPrint('Không có quyền truy cập microphone');
          await _tts.speak('Vui lòng cấp quyền truy cập microphone');
          onError?.call('Không có quyền truy cập microphone');
          return;
        }

        await _speechToText.listen(
          onResult: (result) {
            final text = result.recognizedWords.toLowerCase();
            debugPrint('Nhận diện được: $text');
            processCommand(text);
          },
          localeId: 'vi_VN',
        );
        await _tts.speak('Đang lắng nghe...');
      } catch (e) {
        debugPrint('Lỗi khi bắt đầu lắng nghe: $e');
        onError?.call(e.toString());
      }
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    await _tts.speak('Đã dừng lắng nghe');
  }

  void processCommand(String command) {
    if (command.contains('bật') || command.contains('mở')) {
      onCommandRecognized?.call('on');
      _tts.speak('Đã bật thiết bị');
    } else if (command.contains('tắt') || command.contains('đóng')) {
      onCommandRecognized?.call('off');
      _tts.speak('Đã tắt thiết bị');
    }
  }

  bool get isListening => _speechToText.isListening;
}
