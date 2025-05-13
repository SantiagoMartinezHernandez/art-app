import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform; // For platform-specific checks

class GloveControlScreen extends StatefulWidget {
  const GloveControlScreen({super.key});

  @override
  State<GloveControlScreen> createState() => _GloveControlScreenState();
}

class _GloveControlScreenState extends State<GloveControlScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  // TODO: Add variables for connection state, services, characteristics

  @override
  void initState() {
    super.initState();
    _checkBluetoothAdapterState();
    // Listen to adapter state changes
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      setState(() {
        _adapterState = state;
      });
      if (state == BluetoothAdapterState.on) {
        _requestPermissionsAndScan();
      }
    });
  }

  Future<void> _checkBluetoothAdapterState() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      // Show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bluetooth is not supported on this device."),
          ),
        );
      }
      return;
    }
    _adapterState = await FlutterBluePlus.adapterState.first;
    setState(() {}); // Update UI
    if (_adapterState == BluetoothAdapterState.on) {
      _requestPermissionsAndScan();
    }
  }

  Future<void> _requestPermissionsAndScan() async {
    print("Requesting permissions...");
    Map<Permission, PermissionStatus> statuses = {};

    if (Platform.isAndroid) {
      // For Android, request location and new Bluetooth permissions
      statuses =
          await [
            Permission.location,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ].request();
    } else if (Platform.isIOS) {
      // For iOS, request Bluetooth permission
      // Location is handled via Info.plist but good to check
      statuses =
          await [
            Permission.bluetooth,
            Permission.locationWhenInUse, // Or always if needed
          ].request();
    }

    bool permissionsGranted = true;
    statuses.forEach((permission, status) {
      print("$permission permission status: $status");
      if (!status.isGranted) {
        permissionsGranted = false;
      }
    });

    if (permissionsGranted) {
      print("All required permissions granted.");
      _startScan();
    } else {
      print("Not all permissions granted. Cannot scan.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Bluetooth and Location permissions are required to scan for devices.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startScan() {
    if (_adapterState != BluetoothAdapterState.on) {
      print("Bluetooth is off. Cannot scan.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please turn on Bluetooth to scan for devices."),
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults = []; // Clear previous results
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen(
      (results) {
        // Filter for your specific device if possible (e.g., by name)
        // This is a basic example, you might want to filter more specifically
        // For now, we add all non-empty named devices
        setState(() {
          _scanResults =
              results.where((r) => r.device.platformName.isNotEmpty).toList();
        });
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
        print("Scan finished.");
      },
    );

    // Stop scan after timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (_isScanning) {
        FlutterBluePlus.stopScan();
        setState(() {
          _isScanning = false;
        });
        print("Scan stopped by timeout.");
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_connectedDevice != null) {
      await _disconnectFromDevice();
    }
    print("Connecting to ${device.platformName} (${device.remoteId})");
    try {
      // Listen to connection state changes
      var subscription = device.connectionState.listen((
        BluetoothConnectionState state,
      ) async {
        if (state == BluetoothConnectionState.connected) {
          print("Connected to ${device.platformName}");
          setState(() {
            _connectedDevice = device;
          });
          // TODO: Discover services and characteristics here
          // await device.discoverServices();
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connected to ${device.platformName}")));
        } else if (state == BluetoothConnectionState.disconnected) {
          print("Disconnected from ${device.platformName}");
          setState(() {
            _connectedDevice = null;
          });
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Disconnected from ${device.platformName}")));
        }
      });

      // Add to a list of subscriptions to cancel later
      // device.cancelWhenDisconnected(subscription, delayed:true, next:true);

      await device.connect(timeout: const Duration(seconds: 15));
    } catch (e) {
      print("Error connecting to device: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error connecting: ${e.toString().substring(0, 30)}...",
            ),
          ),
        );
      }
    }
  }

  Future<void> _disconnectFromDevice() async {
    if (_connectedDevice != null) {
      print("Disconnecting from ${_connectedDevice!.platformName}");
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
      });
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan(); // Stop scanning when the widget is disposed
    // TODO: Dispose of any BLE subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bluetooth: ${_adapterState.toString().split('.').last.toUpperCase()}",
              ),
              ElevatedButton(
                onPressed: _isScanning ? null : _requestPermissionsAndScan,
                child: Text(_isScanning ? "Scanning..." : "Scan for Glove"),
              ),
            ],
          ),
        ),
        if (_connectedDevice != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                title: Text("Connected: ${_connectedDevice!.platformName}"),
                subtitle: Text(_connectedDevice!.remoteId.toString()),
                trailing: ElevatedButton(
                  onPressed: _disconnectFromDevice,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Disconnect"),
                ),
              ),
            ),
          ),
        const Divider(),
        Text(
          _isScanning && _scanResults.isEmpty
              ? "Scanning, please wait..."
              : "Found Devices:",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Expanded(
          child:
              _scanResults.isEmpty && !_isScanning
                  ? const Center(child: Text("No devices found. Try scanning."))
                  : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      ScanResult result = _scanResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          title: Text(
                            result.device.platformName.isNotEmpty
                                ? result.device.platformName
                                : "Unknown Device",
                          ),
                          subtitle: Text(result.device.remoteId.toString()),
                          trailing: Text("RSSI: ${result.rssi}"),
                          onTap: () => _connectToDevice(result.device),
                        ),
                      );
                    },
                  ),
        ),
        const Divider(),
        // Placeholder for actual control UI
        if (_connectedDevice != null)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Glove Controls (Placeholder)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        // TODO: Add Slider for intensity, Buttons for modes
      ],
    );
  }
}
