import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Home',
      theme: ThemeData(
        primaryColor: Color(0xFFDB3022),
        scaffoldBackgroundColor: Color(0xFFF9F9F9),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(0xFFDB3022, {
            50: Color(0xFFFBEAE7),
            100: Color(0xFFF6C9C1),
            200: Color(0xFFF0A59A),
            300: Color(0xFFEA8173),
            400: Color(0xFFE56655),
            500: Color(0xFFDB3022),
            600: Color(0xFFD62C1F),
            700: Color(0xFFCF261B),
            800: Color(0xFFC92117),
            900: Color(0xFFBF180F),
          }),
        ).copyWith(
          surface: Colors.white,
          onSurface: Color(0xFF222222),
          onBackground: Color(0xFF222222),
          background: Color(0xFFF9F9F9),
          error: Color(0xFFF01F0E),
        ),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    Container(), // Các màn hình khác
    Container(),
    Container(),
    Container(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Bag',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFDB3022),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCategorySection('Phòng khách'),
          _buildDeviceGrid(),
          _buildCategorySection('Phòng bếp'),
          _buildDeviceGrid(),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Thêm thiết bị',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => DeviceCard(),
    );
  }
}

class DeviceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            const Placeholder(
              fallbackHeight: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Tên thiết bị',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF222222),
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
