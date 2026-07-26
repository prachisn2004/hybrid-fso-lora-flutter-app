import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import '../services/secure_storage_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _terminalController = TextEditingController();
  final List<String> _consoleLogs = [
    "[SYS] Laser Carrier Established @ 1550nm.",
    "[SYS] Link status: OPTICAL EXCELLENT.",
    "[RX] Node 2: Standing by for data stream.",
  ];

  // Bluetooth State Variables
  BluetoothConnection? _connection;
  StreamSubscription? _dataSubscription;
  bool _isConnecting = true;
  bool _isConnected = false;

  // Dynamic Telemetry State Variables
  double _rssiValue = -32.5;
  double _berValue = 1.2e-9;
  double _driftX = 0.05;
  double _driftY = -0.08;
  bool _isHybridFailoverEnabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the connection once the context is ready to extract arguments
    if (_connection == null && _isConnecting) {
      final device =
          ModalRoute.of(context)?.settings.arguments as BluetoothDevice?;
      if (device != null) {
        _connectToHardwareNode(device);
      } else {
        setState(() {
          _isConnecting = false;
          _consoleLogs
              .add("[SYS] No device selected. Running in Simulator Mode.");
        });
      }
    }
  }

  // Establishes the real RF Classic connection to the ESP32 Gateway
  Future<void> _connectToHardwareNode(BluetoothDevice device) async {
    try {
      setState(() {
        _consoleLogs.add("[SYS] Connecting to RF Node: ${device.name}...");
      });

      _connection = await FlutterBlueClassic().connect(device.address);

      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _consoleLogs.add("[SYS] Bluetooth Link Established Successfully!");
      });

      // Handle continuous byte stream data from ESP32
      _dataSubscription = _connection?.input?.listen((Uint8List data) {
        final incomingMessage = utf8.decode(data);
        _processIncomingTelemetry(incomingMessage);
      }, onError: (error) {
        setState(() {
          _consoleLogs.add("[ERROR] Data link exception: $error");
          _isConnected = false;
        });
      }, onDone: () {
        setState(() {
          _consoleLogs.add(
              "[SYS] Bluetooth connection dropped by remote hardware node.");
          _isConnected = false;
        });
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _consoleLogs.add("[ERROR] Hardware handshake failure: $e");
      });
    }
  }

  // Parses data messages from the ESP32 dynamically
  void _processIncomingTelemetry(String message) {
    setState(() {
      // Split by lines in case multiple messages arrive back-to-back
      List<String> lines = message.split('\n');
      for (var line in lines) {
        String data = line.trim();
        if (data.isEmpty) continue;

        // Catch internal metric frames sent by the ESP32 Telemetry Engine
        if (data.startsWith("RSSI:")) {
          final extractedValue = data.split(":");
          if (extractedValue.length > 1) {
            _rssiValue = double.tryParse(extractedValue[1]) ?? _rssiValue;
          }
        } else {
          // Standard system messages are appended directly to the Green console log window
          _consoleLogs.add(data);
        }
      }
    });
  }

  // Transmits terminal payloads via serial Bluetooth
  void _sendLaserPacket() async {
    final payload = _terminalController.text.trim();
    if (payload.isEmpty) return;

    setState(() {
      _consoleLogs.add("[TX] Terminal Command: '$payload'");
    });
    _terminalController.clear();

    if (_isConnected && _connection != null) {
      try {
        // Appending \n ensures readStringUntil('\n') on the Arduino executes reliably
        _connection!.output.add(utf8.encode("$payload\n"));
        await _connection!.output.allSent;
      } catch (e) {
        setState(() {
          _consoleLogs.add("[ERROR] Packet loss. Transmission failed: $e");
        });
      }
    } else {
      // Simulated link fallback mode logic
      setState(() {
        _consoleLogs
            .add("[SYS] (Sim) Encoding packet to PRBS-31 optical frames...");
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _consoleLogs.add("[RX] Node 2: Acknowledged command reception.");
        });
      });
    }
  }

  // Transmits special hardware action frames on switch toggle
  void _toggleOpticalBeam(bool val) async {
    setState(() {
      _isHybridFailoverEnabled = val;
    });

    if (_isConnected && _connection != null) {
      String commandString = val ? "CMD:BEAM:ON\n" : "CMD:BEAM:OFF\n";
      try {
        _connection!.output.add(utf8.encode(commandString));
        await _connection!.output.allSent;
      } catch (e) {
        setState(() {
          _consoleLogs
              .add("[ERROR] Remote control change request rejected: $e");
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await SecureStorageService.deleteUserToken();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildPositionCoordinate(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.cyan,
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connection?.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device =
        ModalRoute.of(context)?.settings.arguments as BluetoothDevice?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FSO Control Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Bluetooth Connection Status Card
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.link,
                        color: _isConnected ? Colors.greenAccent : Colors.cyan,
                        size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Linked Hardware Node:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            _isConnecting
                                ? 'Connecting...'
                                : (_isConnected && device != null
                                    ? '${device.name} (${device.address})'
                                    : 'Simulator Mode'),
                            style: TextStyle(color: Colors.grey[400]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Spatial position coordinates card
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NODE SPATIAL ALIGNMENT',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPositionCoordinate(
                            'PITCH', '${_driftX.toStringAsFixed(2)}°'),
                        _buildPositionCoordinate('YAW', '180.00°'),
                        _buildPositionCoordinate(
                            'ROLL', '${_driftY.toStringAsFixed(2)}°'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Telemetry Readouts Section
            const Text(
              'LINK METRICS',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Optical RSSI'),
                    subtitle: Text('${_rssiValue.toStringAsFixed(1)} dBm'),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Bit Error Rate'),
                    subtitle: Text(_berValue.toStringAsExponential(2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transmission Toggle Switch
            const Text(
              'OPTICAL TRANSMISSION CONTROLS',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Active Optical Beam Power'),
              subtitle: const Text('Maintain Laser carrier-wave status'),
              value: _isHybridFailoverEnabled,
              activeColor: Colors.cyan,
              onChanged:
                  _toggleOpticalBeam, // Calls implementation sending payloads to Arduino
            ),

            // Terminal Window Logs
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: ListView.builder(
                  itemCount: _consoleLogs.length,
                  itemBuilder: (context, index) => Text(
                    _consoleLogs[index],
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Command Entry Input Line
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _terminalController,
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendLaserPacket(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyan),
                  onPressed: _sendLaserPacket,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Status Indicator Badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _isHybridFailoverEnabled
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isHybridFailoverEnabled ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _isHybridFailoverEnabled
                      ? 'BEAM ONLINE / CONNECTED'
                      : 'BEAM BLOCK / OFFLINE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isHybridFailoverEnabled
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
