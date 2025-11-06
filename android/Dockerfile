# Android Build Environment for Memories App
# Based on modern Android SDK with JDK 17
FROM eclipse-temurin:17-jdk-jammy

# Set environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/34.0.0:${PATH}

# Install required system packages
RUN apt-get update && apt-get install -y \
  wget \
  unzip \
  git \
  && rm -rf /var/lib/apt/lists/*

# Download and install Android SDK Command-line Tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
  unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
  mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
  rm /tmp/cmdline-tools.zip

# Accept licenses and install required SDK packages
RUN yes | sdkmanager --licenses && \
  sdkmanager --update && \
  sdkmanager \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0" \
  "cmdline-tools;latest"

# Create debug keystore for signing
RUN mkdir -p /root/.android && \
  keytool -genkey -v -keystore /root/.android/debug.keystore \
  -alias androiddebugkey \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass android \
  -keypass android \
  -dname "CN=Android Debug,O=Android,C=US"

# Set working directory
WORKDIR /app

# Copy gradle wrapper and properties first for better caching
COPY gradle/ gradle/
COPY gradlew gradlew.bat gradle.properties* settings.gradle* build.gradle* ./

# Make gradlew executable
RUN chmod +x gradlew

# Default command (ensure gradlew is executable when volume is mounted)
CMD ["/bin/bash", "-c", "chmod +x ./gradlew 2>/dev/null; exec bash"]

