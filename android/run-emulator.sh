#!/usr/bin/env bash
set -e

# Configuration
AVD_NAME="memories_x86_64"
SYSTEM_IMAGE="system-images;android-34;google_apis_playstore;x86_64"

# Parse arguments
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0"
    echo ""
    echo "Runs the Memories Android app on an x86_64 emulator"
    echo "The emulator includes ARM binary translation for compatibility"
    exit 0
fi

echo "Memories Android Emulator Runner"
echo "Architecture: x86_64 (with ARM translation)"
echo "============================================"
echo ""

# Check for Android SDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
    echo "Error: ANDROID_HOME or ANDROID_SDK_ROOT not set!"
    echo ""
    echo "To use this script, you need Android SDK installed."
    echo "Recommended: Use 'nix run .#run-x86' instead,"
    echo "which handles everything automatically."
    exit 1
fi

# Use ANDROID_SDK_ROOT if ANDROID_HOME is not set
ANDROID_SDK="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"

# Find APK (prefer debug, fall back to release)
APK=""
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    APK="app/build/outputs/apk/debug/app-debug.apk"
    echo "✓ Found debug APK: $APK"
elif [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
    APK="app/build/outputs/apk/release/app-release.apk"
    echo "✓ Found release APK: $APK"
elif [ -f "app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
    APK="app/build/outputs/apk/release/app-release-unsigned.apk"
    echo "✓ Found unsigned release APK: $APK"
else
    echo "✗ Error: No APK found!"
    echo ""
    echo "Please build the app first:"
    echo "  ./build.sh           # for debug APK"
    echo "  ./build-release.sh   # for release APK"
    exit 1
fi

echo ""

# Check if system image is installed
if ! "$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager" --list_installed | grep -q "$SYSTEM_IMAGE"; then
    echo "System image not installed: $SYSTEM_IMAGE"
    echo "Installing system image..."
    yes | "$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager" "$SYSTEM_IMAGE"
fi

# Create AVD if it doesn't exist
if ! "$ANDROID_SDK/cmdline-tools/latest/bin/avdmanager" list avd | grep -q "$AVD_NAME"; then
    echo "Creating AVD: $AVD_NAME"
    echo "no" | "$ANDROID_SDK/cmdline-tools/latest/bin/avdmanager" create avd \
        -n "$AVD_NAME" \
        -k "$SYSTEM_IMAGE" \
        --device "pixel_6" \
        --force
    echo "✓ AVD created"
else
    echo "✓ AVD $AVD_NAME already exists"
fi

echo ""
echo "Starting emulator..."
echo "This may take a few moments..."
echo ""

# Start emulator in background with hardware keyboard enabled
"$ANDROID_SDK/emulator/emulator" -avd "$AVD_NAME" -no-snapshot-load -wipe-data -prop hw.keyboard=yes &
EMULATOR_PID=$!

# Wait for device to boot
echo "Waiting for device to boot..."
"$ANDROID_SDK/platform-tools/adb" wait-for-device

# Wait for system to be ready
echo "Waiting for system to be fully ready..."
while [ "$("$ANDROID_SDK/platform-tools/adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
    sleep 2
    echo -n "."
done
echo ""

echo "✓ Device ready!"
echo ""

# Setup port forwarding
echo "Setting up port forwarding..."
"$ANDROID_SDK/platform-tools/adb" reverse tcp:8443 tcp:8443
echo "✓ Port forwarding: emulator localhost:8443 → host localhost:8443"
echo ""
echo "Network Configuration:"
echo "  From emulator use: https://localhost:8443"
echo "  Or use host alias: https://10.0.2.2:8443"
echo ""

# Install APK
echo "Installing APK..."
"$ANDROID_SDK/platform-tools/adb" install -r "$APK"
echo ""

# Launch app
echo "Launching Memories app..."
"$ANDROID_SDK/platform-tools/adb" shell monkey -p gallery.memories -c android.intent.category.LAUNCHER 1

echo ""
echo "================================="
echo "✓ Memories app is now running!"
echo "  Press Ctrl+C to stop the emulator"
echo "================================="
echo ""

# Wait for emulator process
wait $EMULATOR_PID

