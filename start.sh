#!/bin/bash

# 실제 iPhone 기기에서 Flutter 앱 실행 (BLE 개발용)
echo "🚀 실제 iPhone 기기에서 Flutter 앱을 시작합니다 (BLE 개발용)..."

# 실제 iPhone 기기 찾기
IPHONE_DEVICE=$(flutter devices | grep "김동욱의 iPhone" | head -1 | awk '{print $5}')

if [ -z "$IPHONE_DEVICE" ]; then
    echo "❌ '김동욱의 iPhone' 기기를 찾을 수 없습니다."
    echo "다음 사항을 확인해주세요:"
    echo "1. iPhone이 USB로 연결되어 있는지"
    echo "2. iPhone에서 개발자 모드가 활성화되어 있는지"
    echo "3. 이 Mac에서 신뢰하는 기기로 설정되어 있는지"
    echo ""
    echo "사용 가능한 기기 목록:"
    flutter devices
    exit 1
fi

echo "📱 실제 iPhone 기기 발견: 김동욱의 iPhone (Device ID: $IPHONE_DEVICE)"
echo "🔵 BLE 개발을 위한 실제 기기에서 실행합니다..."

# Flutter 앱 실행
flutter run -d "$IPHONE_DEVICE" 