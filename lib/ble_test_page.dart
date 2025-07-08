import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';
import 'dart:async';

class BleTestPage extends StatefulWidget {
  const BleTestPage({super.key});

  @override
  State<BleTestPage> createState() => _BleTestPageState();
}

class _BleTestPageState extends State<BleTestPage> {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  bool _isConnected = false;
  final List<String> _receivedData = [];
  String? _safety1ch;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // TODO: 실제 기기 이름으로 변경
  final String targetDeviceName = "YOUR_BLE_DEVICE_NAME";

  void _connect() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        _handleScanResult(r);
      }
    });
  }

  Future<void> _handleScanResult(ScanResult r) async {
    if (r.device.platformName == targetDeviceName) {
      FlutterBluePlus.stopScan();
      await r.device.connect();
      setState(() {
        _device = r.device;
        _isConnected = true;
      });
      var services = await r.device.discoverServices();
      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.properties.notify) {
            _characteristic = c;
            await c.setNotifyValue(true);
            c.value.listen(_onDataReceived);
          }
        }
      }
    }
  }

  void _disconnect() async {
    await _device?.disconnect();
    setState(() {
      _isConnected = false;
      _device = null;
      _characteristic = null;
      _receivedData.clear();
      _safety1ch = null;
    });
  }

  void _sendStart() {
    _sendData([0x01, 0x0d, 0x0a]);
  }

  void _sendStop() {
    _sendData([0x02, 0x0d, 0x0a]);
  }

  void _sendData(List<int> bytes) async {
    if (_characteristic != null) {
      await _characteristic!.write(Uint8List.fromList(bytes));
    }
  }

  void _onDataReceived(List<int> data) {
    if (data.length >= 184 &&
        data[0] == 0x40 &&
        data[181] == 0x0d &&
        data[182] == 0x0d) {
      String oneCh = data
          .sublist(6, 9)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      setState(() {
        _receivedData.insert(
          0,
          data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        );
        _safety1ch = oneCh;
      });
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE 테스트')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isConnected ? _disconnect : _connect,
                  child: Text(_isConnected ? '연결해제' : 'BLE 연결'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnected ? _sendStart : null,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnected ? _sendStop : null,
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '1ch 안전도: ${_safety1ch ?? "-"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Text('수신 데이터 (최신순):'),
            Expanded(
              child: ListView.builder(
                itemCount: _receivedData.length,
                itemBuilder: (context, idx) => Text(
                  _receivedData[idx],
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
