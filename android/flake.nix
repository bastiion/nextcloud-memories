{
  description = "Minimal Android Emulator Environment for Memories";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        # Minimal Android SDK with only emulator and platform-tools
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "34" ];
          abiVersions = [ "x86_64" ];
          includeEmulator = true;
          includeSources = false;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis_playstore" ];
          includeNDK = false;
          cmdLineToolsVersion = "13.0";
        };

        androidSdk = androidComposition.androidsdk;

        # Emulator runner for x86_64
        emulatorRunner = pkgs.writeShellScriptBin "run-x86" ''
            set -e

            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
            export PATH="${androidSdk}/libexec/android-sdk/cmdline-tools/13.0/bin:${androidSdk}/libexec/android-sdk/emulator:${androidSdk}/libexec/android-sdk/platform-tools:$PATH"

            AVD_NAME="memories_x86_64"
            SYSTEM_IMAGE="system-images;android-34;google_apis_playstore;x86_64"

            # Find APK (prefer debug, fall back to release)
            APK=""
            if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
              APK="app/build/outputs/apk/debug/app-debug.apk"
              echo "Using debug APK: $APK"
            elif [ -f "app/build/outputs/apk/release/app-release.apk" ]; then
              APK="app/build/outputs/apk/release/app-release.apk"
              echo "Using release APK: $APK"
            elif [ -f "app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
              APK="app/build/outputs/apk/release/app-release-unsigned.apk"
              echo "Using unsigned release APK: $APK"
            else
              echo "Error: No APK found!"
              echo "Please run ./build.sh or ./build-release.sh first."
              exit 1
            fi

            # Create AVD if it doesn't exist
            if ! avdmanager list avd | grep -q "$AVD_NAME"; then
              echo "Creating AVD: $AVD_NAME with $SYSTEM_IMAGE"
              echo "no" | avdmanager create avd \
                -n "$AVD_NAME" \
                -k "$SYSTEM_IMAGE" \
                --device "pixel_6" \
                --force
            else
              echo "AVD $AVD_NAME already exists"
            fi

            echo "Starting emulator $AVD_NAME..."
            echo "This may take a few moments..."

            # Start emulator in background with hardware keyboard enabled
            emulator -avd "$AVD_NAME" -no-snapshot-load -wipe-data -prop hw.keyboard=yes &
            EMULATOR_PID=$!

            # Wait for device to boot
            echo "Waiting for device to boot..."
            adb wait-for-device

            # Wait for system to be ready
            echo "Waiting for system to be ready..."
            while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
              sleep 2
            done

            echo "Device ready!"

            # Setup port forwarding
            echo "Setting up port forwarding..."
            adb reverse tcp:8443 tcp:8443
            echo "✓ Port forwarding: emulator localhost:8443 → host localhost:8443"
            echo ""
            echo "Network Configuration:"
            echo "  From emulator use: https://localhost:8443"
            echo "  Or use host alias: https://10.0.2.2:8443"
            echo ""

            # Install APK
            echo "Installing APK..."
            adb install -r "$APK"

            # Launch app
            echo "Launching Memories app..."
            adb shell monkey -p gallery.memories -c android.intent.category.LAUNCHER 1

            echo ""
            echo "✓ Memories app is now running in the emulator!"
            echo "  Press Ctrl+C to stop the emulator"
            echo ""

            # Wait for emulator process
            wait $EMULATOR_PID
          '';

      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [ androidSdk ];

          shellHook = ''
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
            export PATH="${androidSdk}/libexec/android-sdk/cmdline-tools/13.0/bin:${androidSdk}/libexec/android-sdk/emulator:${androidSdk}/libexec/android-sdk/platform-tools:$PATH"
            
            echo "Android Emulator Environment Ready"
            echo "Available command:"
            echo "  nix run .#run-x86  - Run app on x86_64 emulator"
            echo ""
            echo "Note: x86_64 emulator includes ARM binary translation"
            echo ""
          '';
        };

        packages = {
          run-x86 = emulatorRunner;
          default = emulatorRunner;
        };
      });
}

