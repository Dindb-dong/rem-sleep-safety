#!/bin/bash

# iOS 시뮬레이터에서 Flutter 앱 실행
echo "🚀 iOS 시뮬레이터에서 Flutter 앱을 시작합니다..."

# 시뮬레이터가 실행되지 않았다면 실행
if ! xcrun simctl list devices | grep -q "Booted"; then
    echo "📱 iOS 시뮬레이터를 시작합니다..."
    open -a Simulator
    sleep 10
fi

# iOS 시뮬레이터 디바이스 찾기
IOS_DEVICE=$(flutter devices | grep "ios" | head -1 | awk '{print $5}')

if [ -z "$IOS_DEVICE" ]; then
    echo "❌ iOS 시뮬레이터를 찾을 수 없습니다."
    echo "시뮬레이터가 실행 중인지 확인해주세요."
    exit 1
fi

echo "📱 iOS 시뮬레이터 발견: $IOS_DEVICE"

# Flutter 앱 실행
flutter run -d "$IOS_DEVICE" 