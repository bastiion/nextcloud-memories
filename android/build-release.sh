#!/usr/bin/env bash
set -e

echo "Building Memories Android APK (Release)..."

# Check for signing configuration
if [ ! -f "keystore.properties" ]; then
    echo ""
    echo "⚠ Warning: keystore.properties not found!"
    echo "For release builds, you need to create keystore.properties with:"
    echo "  storeFile=/path/to/your.keystore"
    echo "  storePassword=your_store_password"
    echo "  keyAlias=your_key_alias"
    echo "  keyPassword=your_key_password"
    echo ""
    echo "Building unsigned release APK instead..."
fi

# Check if we should use Docker or native build
if command -v docker &> /dev/null && [ -f "Dockerfile" ]; then
    echo "Using Docker for build..."
    
    # Build Docker image if it doesn't exist
    if ! docker images | grep -q "memories-android-builder"; then
        echo "Building Docker image..."
        docker compose build
    fi
    
    # Run build inside container
    docker compose run --rm android-builder bash -c "chmod +x ./gradlew && ./gradlew assembleRelease"
else
    echo "Using native Gradle for build..."
    ./gradlew assembleRelease
fi

# Check if APK was created
if [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
    echo ""
    echo "✓ Build successful!"
    echo "APK location: app/build/outputs/apk/release/app-release.apk"
    ls -lh app/build/outputs/apk/release/app-release.apk
elif [ -f "app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
    echo ""
    echo "✓ Build successful (unsigned)!"
    echo "APK location: app/build/outputs/apk/release/app-release-unsigned.apk"
    ls -lh app/build/outputs/apk/release/app-release-unsigned.apk
else
    echo ""
    echo "✗ Build failed - APK not found"
    exit 1
fi

