// NUS (Nordic UART Service) UUID 설명
// NUS_BASE_UUID: 128비트 UUID 템플릿 (예: 9ECA DC24 0EE5 A9E0 93F3 A3B5 0000 406E)
// BLE_UUID_NUS_TX_CHARACTERISTIC: 0x0003 (송신용)
// BLE_UUID_NUS_RX_CHARACTERISTIC: 0x0002 (수신용)
// 실제 사용되는 UUID는 Base UUID의 13, 14번째 바이트(0x00, 0x00)가 각각 0x03, 0x00 또는 0x02, 0x00으로 대체되어 생성됩니다.
// 예시:
//   TX: 9ECA DC24 0EE5 A9E0 93F3 A3B5 0003 406E
//   RX: 9ECA DC24 0EE5 A9E0 93F3 A3B5 0002 406E
// 이 UUID로 BLE 서비스/캐릭터리스틱을 찾고 데이터 송수신에 사용합니다.

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
  final List<String> _logs = []; // 로그 저장용

  // NUS UUID 정의
  final Guid nusServiceUuid = Guid("6e406000-b5a3-f393-e0a9-e50e24dcca9e");
  final Guid nusTxCharUuid = Guid("6e406003-b5a3-f393-e0a9-e50e24dcca9e");
  final Guid nusRxCharUuid = Guid("6e406002-b5a3-f393-e0a9-e50e24dcca9e");

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
    setState(() {
      _logs.insert(0, "[$timestamp] $message");
      if (_logs.length > 50) _logs.removeLast(); // 최대 50개 로그만 유지
    });
    print("[BLE_LOG] $message"); // 콘솔에도 출력
  }

  void _connect() {
    _addLog("🔍 BLE 스캔을 시작합니다...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _addLog("📡 스캔 결과: ${results.length}개 기기 발견");
      for (ScanResult r in results) {
        _handleScanResult(r);
      }
    });
  }

  Future<void> _handleScanResult(ScanResult r) async {
    final deviceName = r.device.platformName.isNotEmpty
        ? r.device.platformName
        : r.device.remoteId.toString();

    _addLog("📱 기기 발견: $deviceName (${r.device.remoteId})");
    _addLog("   - RSSI: ${r.rssi} dBm");
    _addLog("   - 서비스 UUID 개수: ${r.advertisementData.serviceUuids.length}");

    // UUID 기반으로 서비스가 있는 기기만 연결
    final serviceUuids = r.advertisementData.serviceUuids;
    if (serviceUuids.contains(nusServiceUuid)) {
      _addLog("✅ NUS 서비스 발견! 연결을 시도합니다...");
      FlutterBluePlus.stopScan();
      _addLog("🛑 스캔을 중지했습니다.");

      try {
        _addLog("🔗 기기에 연결 중...");
        await r.device.connect();
        _addLog("✅ 기기 연결 성공!");

        setState(() {
          _device = r.device;
          _isConnected = true;
        });

        _addLog("🔍 서비스를 탐색 중...");
        var services = await r.device.discoverServices();
        _addLog("📋 발견된 서비스 개수: ${services.length}");

        for (var s in services) {
          _addLog("   - 서비스: ${s.uuid}");
          if (s.uuid == nusServiceUuid) {
            _addLog("✅ NUS 서비스를 찾았습니다!");
            _addLog("   - 캐릭터리스틱 개수: ${s.characteristics.length}");

            for (var c in s.characteristics) {
              _addLog("     - 캐릭터리스틱: ${c.uuid}");
              _addLog("       속성: ${c.properties}");

              if (c.uuid == nusTxCharUuid && c.properties.notify) {
                _addLog("✅ TX 캐릭터리스틱 발견! 알림을 활성화합니다...");
                _characteristic = c;
                await c.setNotifyValue(true);
                _addLog("✅ 알림 활성화 완료!");
                c.lastValueStream.listen(_onDataReceived);
                _addLog("🎧 데이터 수신 대기 중...");
              }
            }
          }
        }
      } catch (e) {
        _addLog("❌ 연결 실패: $e");
        setState(() {
          _isConnected = false;
          _device = null;
          _characteristic = null;
        });
      }
    } else {
      _addLog("❌ NUS 서비스가 없습니다. 건너뜁니다.");
    }
  }

  void _disconnect() async {
    if (_device != null) {
      _addLog("🔌 연결을 해제합니다...");
      try {
        await _device!.disconnect();
        _addLog("✅ 연결 해제 완료!");
      } catch (e) {
        _addLog("❌ 연결 해제 실패: $e");
      }
    }

    setState(() {
      _isConnected = false;
      _device = null;
      _characteristic = null;
      _receivedData.clear();
      _safety1ch = null;
    });
  }

  void _sendStart() {
    _addLog("▶️ Start 명령을 전송합니다...");
    _sendData([0x01, 0x0d, 0x0a]);
  }

  void _sendStop() {
    _addLog("⏹️ Stop 명령을 전송합니다...");
    _sendData([0x02, 0x0d, 0x0a]);
  }

  void _sendData(List<int> bytes) async {
    if (_characteristic != null) {
      try {
        _addLog(
          "📤 데이터 전송: ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
        );
        await _characteristic!.write(Uint8List.fromList(bytes));
        _addLog("✅ 데이터 전송 완료!");
      } catch (e) {
        _addLog("❌ 데이터 전송 실패: $e");
      }
    } else {
      _addLog("❌ 캐릭터리스틱이 없습니다. 연결을 확인해주세요.");
    }
  }

  void _onDataReceived(List<int> data) {
    _addLog("📥 데이터 수신: ${data.length}바이트");
    _addLog(
      "   - 데이터: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    if (data.length >= 184 &&
        data[0] == 0x40 &&
        data[181] == 0x0d &&
        data[182] == 0x0d) {
      String oneCh = data
          .sublist(6, 9)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      _addLog("✅ 유효한 데이터 패킷! 1ch 안전도: $oneCh");

      setState(() {
        _receivedData.insert(
          0,
          data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' '),
        );
        _safety1ch = oneCh;
      });
    } else {
      _addLog(
        "⚠️ 유효하지 않은 데이터 패킷 (길이: ${data.length}, 시작: 0x${data.isNotEmpty ? data[0].toRadixString(16) : 'N/A'})",
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _addLog("앱 시작됨 (initState)");
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BLE 로그 (최신순):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('로그 지우기'),
                ),
              ],
            ),
            SizedBox(
              height: 180, // 고정 높이로 변경
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, idx) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      _logs[idx],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
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
