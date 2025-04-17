import 'package:flutter/material.dart';
// Thêm import cho home_screen.dart
import 'home_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Định nghĩa bảng màu
    const primaryColor = Color(0xFF0077B6); // Xanh biển chính
    const secondaryColor = Color(0xFF00B4D8); // Xanh dương nhạt
    const accentColor = Color(0xFFCAF0F8); // Xanh rất nhạt / Trắng xanh
    const backgroundColor = Color(0xFFF0F8FF); // AliceBlue - Nền sáng
    const cardBackgroundColor = Colors.white;
    const textColor = Color(0xFF03045E); // Xanh đen cho chữ

    final baseTheme = ThemeData.light(useMaterial3: true);

    return MaterialApp(
      title: 'Smart Home App',
      debugShowCheckedModeBanner: false, // Tắt banner debug
      theme: baseTheme.copyWith(
        // Bảng màu
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: accentColor, // Có thể dùng làm màu nhấn
          background: backgroundColor,
          surface: cardBackgroundColor, // Màu nền cho Card, Dialog,...
          onPrimary: Colors.white, // Chữ/icon trên nền primary
          onSecondary: Colors.black, // Chữ/icon trên nền secondary
          onBackground: textColor, // Chữ/icon trên nền background
          onSurface: textColor, // Chữ/icon trên nền surface (Card,...)
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        // Font chữ
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),
        primaryTextTheme:
            GoogleFonts.poppinsTextTheme(baseTheme.primaryTextTheme),
        // Tùy chỉnh AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor:
              Colors.transparent, // Nền trong suốt theo thiết kế cũ
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            // Không dùng fontFamily ở đây vì textTheme đã áp dụng GoogleFonts
          ),
        ),
        // Tùy chỉnh TabBar
        tabBarTheme: TabBarTheme(
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: textColor.withOpacity(0.6),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
        ),
        // Tùy chỉnh Card
        cardTheme: CardTheme(
          elevation: 2.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          color: cardBackgroundColor, // Màu nền thẻ
          surfaceTintColor:
              Colors.transparent, // Bỏ hiệu ứng màu khi scroll trong M3
        ),
        // Tùy chỉnh Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor; // Màu nút trượt khi bật
            }
            return Colors.grey.shade400; // Màu nút trượt khi tắt
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor.withOpacity(0.5); // Màu đường ray khi bật
            }
            return Colors.grey.shade200; // Màu đường ray khi tắt
          }),
          trackOutlineColor:
              WidgetStateProperty.all(Colors.transparent), // Bỏ viền M3
        ),
      ),
      home: const HomeScreen(), // Sử dụng HomeScreen
    );
  }
}
