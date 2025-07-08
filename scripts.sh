#!/bin/bash

# Flutter 개발 편의 스크립트

case "$1" in
    "start")
        echo "🚀 Flutter 앱 시작..."
        flutter run
        ;;
    "ios")
        echo "🍎 iOS 시뮬레이터에서 실행..."
        # iOS 시뮬레이터 디바이스 찾기
        IOS_DEVICE=$(flutter devices | grep "ios" | head -1 | awk '{print $5}')
        
        if [ -z "$IOS_DEVICE" ]; then
            echo "❌ iOS 시뮬레이터를 찾을 수 없습니다."
            echo "시뮬레이터가 실행 중인지 확인해주세요."
            exit 1
        fi
        
        echo "📱 iOS 시뮬레이터 발견: $IOS_DEVICE"
        flutter run -d "$IOS_DEVICE"
        ;;
    "android")
        echo "🤖 Android 에뮬레이터에서 실행..."
        flutter run -d android
        ;;
    "web")
        echo "🌐 웹에서 실행..."
        flutter run -d chrome
        ;;
    "clean")
        echo "🧹 빌드 캐시 정리..."
        flutter clean
        ;;
    "get")
        echo "📦 의존성 설치..."
        flutter pub get
        ;;
    "upgrade")
        echo "⬆️ 의존성 업그레이드..."
        flutter pub upgrade
        ;;
    "doctor")
        echo "🏥 Flutter 환경 진단..."
        flutter doctor
        ;;
    *)
        echo "사용법: ./scripts.sh [명령어]"
        echo "명령어:"
        echo "  start    - 기본 실행"
        echo "  ios      - iOS 시뮬레이터에서 실행"
        echo "  android  - Android 에뮬레이터에서 실행"
        echo "  web      - 웹에서 실행"
        echo "  clean    - 빌드 캐시 정리"
        echo "  get      - 의존성 설치"
        echo "  upgrade  - 의존성 업그레이드"
        echo "  doctor   - 환경 진단"
        ;;
esac 