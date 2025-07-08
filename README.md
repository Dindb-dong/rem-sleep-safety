# REM 수면 안전도 검사 앱 (RSS)

본 프로젝트는 저전력 BLE 기기와 연동하여 렘(REM) 수면 중 안전도를 모니터링하고, 데이터를 서버로 전송·분석하는 Flutter 기반 앱입니다.

---

## 시스템 구성

```
[기기]
  - 저전력 MCU (예: nRF52840, ESP32 등)
  - BLE로 스마트폰에 데이터 전송

  ⇄

[앱 (Flutter)]
  - BLE로 데이터 수신, 30초마다 데이터 압축
  - 압축: lightweight (RLE, delta encoding 등)
  - 백그라운드에서 서버로 전송 (REST or WebSocket)

  ⇄

[서버]
  - 데이터 저장, 분석, 피드백 리포트 생성
```

---

## 주요 동작 및 요구사항

- 앱은 **백그라운드 상태** (화면 꺼짐 포함)에서도:
  1. BLE 기기와 연결 유지
  2. 30초마다 데이터 수신
  3. 서버로 전송
- **배터리 소모, 발열, OS 강제종료 최소화** 필요
- 백그라운드 작업 권한 필요 → Flutter에서 `flutter_background`, `workmanager`, `android_alarm_manager_plus` 등 조합 사용

---

## BLE 통신 및 데이터 흐름

- [flutter_reactive_ble](https://pub.dev/packages/flutter_reactive_ble) 사용
  - 백그라운드 연결 유지에 더 안정적
  - Peripheral의 advertise interval 설정도 기기 쪽에서 조정 가능
  - > `flutter_blue`는 백그라운드 안정성이 낮고, iOS에서 종종 끊김

### 30초마다 데이터 수신 방식

- **기기에서 자체적으로 30초마다 advertising 또는 notification**
  - 앱이 polling하지 않고, 기기에서 30초마다 BLE notify/send
  - 앱은 수신 대기만 하므로 배터리 및 CPU 소모 최소화
  - → 기기가 `notifyCharacteristicChanged`만 보내면, 앱은 `flutter_reactive_ble`의 stream 구독만 하면 됨

---

## 배터리 및 발열 최적화

- BLE 기기 → **간결한 이진 데이터**로 전송 (예: Base64, CBOR, delta encoding)
- 앱은 수신 후 바로 서버로 전송 또는 저장, 연산 최소화
- 데이터 수신 중에는 **UI 갱신하지 않음** (백그라운드이므로 필요 없음)

---

## 요약

- 저전력 BLE 기기와 연동하여 렘 수면 중 안전도 데이터를 수집
- Flutter 앱이 백그라운드에서 BLE 데이터 수신 및 서버 전송
- 배터리, 발열, OS 강제종료 최소화에 중점
- 서버에서 데이터 저장, 분석, 피드백 리포트 제공

---

## 실행 및 개발 스크립트 사용법

### scripts.sh

Flutter 앱을 다양한 환경에서 실행하거나, 의존성 관리, 빌드 정리 등 개발 편의를 위한 통합 스크립트입니다.

```bash
./scripts.sh [명령어]
```

- **start**: 기본 실행 (연결된 디바이스에서 flutter run)
- **ios**: iOS 시뮬레이터에서 실행
- **android**: Android 에뮬레이터에서 실행
- **web**: 웹(Chrome)에서 실행
- **clean**: 빌드 캐시 정리 (flutter clean)
- **get**: 의존성 설치 (flutter pub get)
- **upgrade**: 의존성 업그레이드 (flutter pub upgrade)
- **doctor**: Flutter 환경 진단 (flutter doctor)

예시:

```bash
./scripts.sh ios      # iOS 시뮬레이터에서 실행
./scripts.sh android  # Android 에뮬레이터에서 실행
./scripts.sh clean    # 빌드 캐시 정리
```

### start.sh

iOS 시뮬레이터에서 Flutter 앱을 자동으로 실행하는 스크립트입니다. 시뮬레이터가 꺼져 있으면 자동으로 실행 후, 첫 번째 iOS 시뮬레이터에 앱을 빌드/실행합니다.

```bash
./start.sh
```
