import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';

class HardwareBindPage extends StatefulWidget {
  const HardwareBindPage({super.key});

  @override
  State<HardwareBindPage> createState() => _HardwareBindPageState();
}

class _HardwareBindPageState extends State<HardwareBindPage> {
  final FlutterBlueClassic _blueClassic = FlutterBlueClassic();

  // Scanner state variables
  List<BluetoothDevice> _scanResults = [];
  StreamSubscription? _scanSubscription;
  StreamSubscription? _isScanningSubscription;
  bool _isScanning = false;

  // Form Field Controllers for Node metadata
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _callsignController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _nodeIdController = TextEditingController();

  // Dynamic values for toggles
  bool _autoReconnect = true;
  bool _highPowerLaserMode = false;

  @override
  void initState() {
    super.initState();

    // Monitor scanning state changes from the plugin
    _isScanningSubscription = _blueClassic.isScanning.listen((scanning) {
      if (mounted) {
        setState(() {
          _isScanning = scanning;
        });
      }
    });

    // Handle discovered classic Bluetooth hardware nodes
    _scanSubscription = _blueClassic.scanResults.listen((device) {
      if (mounted) {
        setState(() {
          // Prevent showing duplicate device listings in the scan list
          if (!_scanResults.any((d) => d.address == device.address)) {
            _scanResults.add(device);
          }
        });
      }
    });

    // Auto-trigger an initial hardware scan upon page launch
    _checkPermissionsAndStartScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _callsignController.dispose();
    _passcodeController.dispose();
    _nodeIdController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndStartScan() async {
    // Request vital Bluetooth hardware permissions needed on modern operating systems
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]?.isGranted == true &&
        statuses[Permission.bluetoothConnect]?.isGranted == true) {
      _startScan();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bluetooth & Location permissions are required.')),
        );
      }
    }
  }

  void _startScan() {
    if (_isScanning) return;
    setState(() {
      _scanResults.clear();
    });
    try {
      _blueClassic.startScan();
    } catch (e) {
      debugPrint("Error starting hardware scan: $e");
    }
  }

  void _stopScan() {
    if (!_isScanning) return;
    try {
      _blueClassic.stopScan();
    } catch (e) {
      debugPrint("Error stopping hardware scan: $e");
    }
  }

  // Helper widget to build input fields cleanly
  Widget _buildHardwareInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isObscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: Colors.cyan, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return 'This field cannot be left blank';
          }
          return null;
        },
      ),
    );
  }

  // Helper widget to clean up accessory toggle configurations with modern properties
  Widget _buildAccessoryTile({
    required String title,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        value: isEnabled,
        activeColor: Colors.cyan,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'FSO HARDWARE LINK',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh,
                color: Colors.cyan),
            onPressed: _isScanning ? _stopScan : _checkPermissionsAndStartScan,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PHYSICAL / WIRELESS PORT CONFIGURATION',
                style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              const SizedBox(height: 20),

              // Node Credentials Binding Forms
              _buildHardwareInputField(
                controller: _callsignController,
                hintText: 'Operator Callsign / ID',
                prefixIcon: Icons.person_outline,
              ),
              _buildHardwareInputField(
                controller: _passcodeController,
                hintText: 'Access Passcode',
                prefixIcon: Icons.lock_outline,
                isObscure: true,
              ),
              _buildHardwareInputField(
                controller: _nodeIdController,
                hintText: 'Target Transceiver Node ID',
                prefixIcon: Icons.router_outlined,
              ),

              const SizedBox(height: 8),

              // Accessory settings
              _buildAccessoryTile(
                title: 'Auto-Reconnect Link Channel',
                isEnabled: _autoReconnect,
                onChanged: (val) => setState(() => _autoReconnect = val),
              ),
              _buildAccessoryTile(
                title: 'Boost Optical Transceiver Amplification',
                isEnabled: _highPowerLaserMode,
                onChanged: (val) => setState(() => _highPowerLaserMode = val),
              ),

              const SizedBox(height: 16),
              const Text(
                'DISCOVERED LOCAL HARDWARE NODES',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              const SizedBox(height: 10),

              // Discovered Hardware Nodes Dynamic List View
              Expanded(
                child: _scanResults.isEmpty
                    ? Center(
                        child: Text(
                          _isScanning
                              ? 'Scanning for nodes...'
                              : 'No hardware nodes detected.',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _scanResults.length,
                        itemBuilder: (context, index) {
                          final device = _scanResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[900]!),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth,
                                  color: Colors.cyan),
                              title: Text(
                                device.name ?? 'Unknown Node Space',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                device.address,
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                              onTap: () {
                                if (_formKey.currentState!.validate()) {
                                  _stopScan();
                                  // Bind and transmit target hardware state down into the telemetry module Dashboard
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/dashboard',
                                    arguments: device,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Action triggers at bottom
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _stopScan();
                    // Fallback to Simulation Mode dashboard if direct item wasn't selected
                    Navigator.pushReplacementNamed(
                      context,
                      '/dashboard',
                      arguments: null,
                    );
                  }
                },
                child: const Text(
                  'CONNECT LINK (SIMULATOR MODE)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
