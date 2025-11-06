#!/usr/bin/env bash
set -e

echo "Rebuilding Memories Android APK (Debug)..."

# Check if we should use Docker or native build
if command -v docker &> /dev/null && [ -f "Dockerfile" ]; then
    echo "Using Docker for rebuild..."
    
    # Build Docker image if it doesn't exist
    if ! docker images | grep -q "memories-android-builder"; then
        echo "Building Docker image..."
        docker compose build
    fi
    
    # Clean and rebuild inside container
    echo "Cleaning previous build..."
    docker compose run --rm android-builder bash -c "./gradlew clean"
    
    echo "Building APK..."
    docker compose run --rm android-builder bash -c "./gradlew assembleDebug"
else
    echo "Using native Gradle for rebuild..."
    echo "Cleaning previous build..."
    ./gradlew clean
    
    echo "Building APK..."
    ./gradlew assembleDebug
fi

# Check if APK was created
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo ""
    echo "✓ Rebuild successful!"
    echo "APK location: app/build/outputs/apk/debug/app-debug.apk"
    ls -lh app/build/outputs/apk/debug/app-debug.apk
else
    echo ""
    echo "✗ Rebuild failed - APK not found"
    exit 1
fi

