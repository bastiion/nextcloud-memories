#!/usr/bin/env bash
set -e

echo "Building Memories Android APK (Debug)..."

# Check if we should use Docker or native build
if command -v docker &> /dev/null && [ -f "Dockerfile" ]; then
    echo "Using Docker for build..."
    
    # Build Docker image if it doesn't exist
    if ! docker images | grep -q "memories-android-builder"; then
        echo "Building Docker image..."
        docker compose build
    fi
    
    # Run build inside container
    docker compose run --rm android-builder bash -c "./gradlew assembleDebug"
else
    echo "Using native Gradle for build..."
    ./gradlew assembleDebug
fi

# Check if APK was created
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo ""
    echo "✓ Build successful!"
    echo "APK location: app/build/outputs/apk/debug/app-debug.apk"
    ls -lh app/build/outputs/apk/debug/app-debug.apk
else
    echo ""
    echo "✗ Build failed - APK not found"
    exit 1
fi

