# Memories Android Wrapper

Android implementation of the NativeX interface.

Note that all code under this tree is licensed under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.html), unlike Memories itself, which is licensed under the AGPLv3 license.

## Build System

This project provides multiple ways to build and test the Android app:

1. **Docker Build Environment** - Reproducible builds in a containerized environment
2. **Native Gradle Build** - Build directly with your local Android SDK
3. **Nix Flake** - Minimal emulator environment for testing (no build tools)

## Quick Start

### Building the App

#### Option 1: Docker Build (Recommended)

The easiest way to build the app with all dependencies managed:

```bash
# Build debug APK
./build.sh

# Clean and rebuild
./rebuild.sh

# Build release APK
./build-release.sh
```

The first build will download the Docker image and dependencies, which may take a few minutes. Subsequent builds are much faster.

#### Option 2: Native Build

If you have Android SDK and JDK 17 installed locally:

```bash
# Build debug APK
./gradlew assembleDebug

# Build release APK
./gradlew assembleRelease
```

### Running on Emulator

#### Option 1: Nix Flake (Recommended)

The easiest way to run the app on an emulator with automatic AVD management:

```bash
# Run on x86_64 emulator (includes ARM binary translation)
nix run .#run-x86
```

The Nix flake will:
- Automatically download and configure the Android SDK emulator
- Create the AVD if it doesn't exist
- Start the emulator
- Setup port forwarding: emulator localhost:8443 → host localhost:8443
- Install the APK (debug or release, whichever is available)
- Launch the app

No manual AVD setup required!

**Network Configuration**: The emulator automatically forwards port 8443 to the host's port 8443. This allows you to access your local Nextcloud instance at `https://localhost:8443` from within the app. Alternatively, you can use `https://10.0.2.2:8443` which always points to the host.

#### Option 2: Manual Script

If you have Android SDK installed locally:

```bash
# Run on x86_64 emulator
./run-emulator.sh
```

## Docker Build Environment

### Architecture

The Docker setup uses:
- Base image: `eclipse-temurin:17-jdk-jammy` (OpenJDK 17)
- Android SDK with API 34 (Android 14)
- Build tools 34.0.0
- Platform tools (adb, etc.)
- Auto-generated debug keystore for signing

### Build Scripts

#### `build.sh`
Builds a debug APK. Automatically detects and uses Docker if available, falls back to native Gradle build.

Output: `app/build/outputs/apk/debug/app-debug.apk`

#### `rebuild.sh`
Cleans the build directory and rebuilds from scratch. Useful when switching branches or after major code changes.

Output: `app/build/outputs/apk/debug/app-debug.apk`

#### `build-release.sh`
Builds a release APK with minification and resource shrinking enabled.

For signed releases, create a `keystore.properties` file with:
```properties
storeFile=/path/to/your.keystore
storePassword=your_store_password
keyAlias=your_key_alias
keyPassword=your_key_password
```

Output: `app/build/outputs/apk/release/app-release.apk` (or `app-release-unsigned.apk`)

### Docker Compose

The `docker-compose.yml` provides an interactive build environment:

```bash
# Build the Docker image
docker-compose build

# Run a shell in the container
docker-compose run --rm android-builder

# Run a specific command
docker-compose run --rm android-builder ./gradlew assembleDebug
```

### Dockerfile Details

The Dockerfile:
1. Installs OpenJDK 17 (required by Gradle 8.1.2)
2. Downloads Android SDK Command-line Tools
3. Installs platform-tools, build-tools, and Android 34 platform
4. Generates a debug keystore for development signing
5. Sets up proper environment variables (ANDROID_HOME, ANDROID_SDK_ROOT)

## Nix Flake Emulator Environment

### Overview

The `flake.nix` provides a **minimal** Android environment focused solely on running emulators for testing. It does NOT include build tools - use Docker for building.

### Features

- **Zero Configuration**: AVDs are created automatically
- **ARM Binary Translation**: x86_64 emulator runs ARM apps transparently
- **Auto APK Detection**: Automatically finds debug or release APK
- **No Manual Setup**: Everything is handled by the Nix runner

### Requirements

- Nix with flakes enabled
- Hardware virtualization support (KVM on Linux)

### Usage

```bash
# Run on x86_64 emulator
nix run .#run-x86

# Enter development shell (provides adb, emulator commands)
nix develop
```

### What the Flake Does

1. Downloads Android SDK with emulator and platform-tools only
2. Creates x86_64 AVD if needed
3. Starts emulator with a clean state and hardware keyboard enabled
4. Sets up port forwarding (localhost:8443)
5. Waits for device to fully boot
6. Installs the APK
7. Launches the Memories app

### Architecture

- **x86_64 with ARM Translation**: The emulator runs on x86_64 hosts but includes built-in ARM binary translation, allowing it to run ARM-compiled APKs transparently. This provides the best performance on x86_64 development machines.

**Note**: The emulator uses Google Play system images which include an updated WebView component, necessary for displaying modern web content like Nextcloud login pages.

## Manual Emulator Script

If you prefer to use your existing Android SDK installation:

```bash
# Run x86_64 emulator
./run-emulator.sh

# Show help
./run-emulator.sh --help
```

The script requires `ANDROID_HOME` or `ANDROID_SDK_ROOT` to be set.

## Network Configuration

### Accessing Host Services from Emulator

The emulator runners automatically setup port forwarding for convenient testing:

**Port Forwarding:**
- Emulator `localhost:8443` → Host `localhost:8443`

This means you can configure the Memories app to connect to `https://localhost:8443` and it will reach your Nextcloud instance on the host at port 8443.

Alternatively, you can always use `https://10.0.2.2:8443` which is a special alias that points to the host's localhost.

### Alternative Methods

If you need to access other host services, you can use:

1. **Special Alias `10.0.2.2`**: Always points to the host's localhost
   ```
   Example: http://10.0.2.2:8080 accesses host's localhost:8080
   ```

2. **Additional Port Forwarding**: You can add more port forwards using adb:
   ```bash
   adb reverse tcp:8080 tcp:8080
   ```

3. **Remove Port Forwarding**: To clear port forwarding:
   ```bash
   adb reverse --remove tcp:443
   ```

## Technical Details

### App Configuration

- **Package**: `gallery.memories`
- **Min SDK**: API 27 (Android 8.1)
- **Target SDK**: API 34 (Android 14)
- **Compile SDK**: API 34
- **Java Version**: JDK 17
- **Kotlin Version**: 1.9.23
- **Gradle Version**: 8.1.2 (via wrapper)

### Build Variants

- **Debug**: Includes debugging symbols, not minified
- **Release**: Minified with ProGuard, resource shrinking enabled

### Key Dependencies

- AndroidX Core, AppCompat, Material Design
- Media3 ExoPlayer for video playback
- Room database for local storage
- OkHttp for network requests
- ExifInterface for photo metadata

## Troubleshooting

### Docker Build Issues

**Problem**: Docker image build is slow or fails

**Solution**: 
```bash
# Clear Docker cache and rebuild
docker-compose build --no-cache
```

**Problem**: Permission errors in container

**Solution**: The container runs as root, ensure your project directory is readable.

### Emulator Issues

**Problem**: Emulator fails to start

**Solution**:
```bash
# Check if KVM is available (Linux)
ls -la /dev/kvm

# Ensure your user is in the kvm group
sudo usermod -a -G kvm $USER
# Log out and back in for changes to take effect
```

**Problem**: AVD creation fails

**Solution**:
```bash
# Clean existing AVD
rm -rf ~/.android/avd/memories_x86_64.*

# Let the script recreate it
nix run .#run-x86
```

**Problem**: APK not found

**Solution**:
```bash
# Build the APK first
./build.sh

# Then run emulator
nix run .#run-x86
```

### Gradle Issues

**Problem**: `Could not resolve dependencies`

**Solution**:
```bash
# Clear Gradle cache
rm -rf ~/.gradle/caches/

# Rebuild
./rebuild.sh
```

**Problem**: `Unsupported Java version`

**Solution**: Ensure you're using JDK 17. The Docker build handles this automatically.

## Development Workflow

Recommended workflow for development:

1. **Make code changes** in your editor
2. **Build the APK**: `./build.sh`
3. **Test on emulator**: `nix run .#run-x86`
4. **Iterate**: Make changes, rebuild, test

For release builds:

1. **Build release APK**: `./build-release.sh`
2. **Test on emulator**: `nix run .#run-x86`
3. **Sign and distribute** the APK

## CI/CD Integration

The Docker setup is ideal for CI/CD pipelines:

```bash
# In your CI script
cd android/
./build.sh

# APK will be at app/build/outputs/apk/debug/app-debug.apk
```

## Additional Resources

- [Android Developer Documentation](https://developer.android.com/)
- [Gradle Build Tool](https://gradle.org/)
- [Nix Package Manager](https://nixos.org/)
- [Docker Documentation](https://docs.docker.com/)
