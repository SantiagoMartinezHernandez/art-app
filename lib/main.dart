import 'package:flutter/material.dart';
import 'screens/calibration.dart';

void main() {
  runApp(const ARTapp());
}

class ARTapp extends StatelessWidget {
  const ARTapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ART',
      theme: ThemeData(
        primarySwatch: Colors.indigo, // You can choose your app's primary color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // To keep track of the selected tab

  // Placeholder screens for now - we will build these out
  static const List<Widget> _widgetOptions = <Widget>[
    GloveControlScreen(), // Index 0
    PlaceholderWidget(color: Colors.lightGreen, text: 'Tremor Log'), // Index 1
    PlaceholderWidget(color: Colors.orangeAccent, text: 'Support'), // Index 2
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ART/Wear App')),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app), // Icon for glove control
            label: 'Control',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics), // Icon for tremor log
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline), // Icon for support
            label: 'Support',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

// A simple placeholder widget to represent our different screens
class PlaceholderWidget extends StatelessWidget {
  final Color color;
  final String text;

  const PlaceholderWidget({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.2),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
