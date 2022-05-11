FROM ubuntu:18.04
MAINTAINER J1ang <akvsdk@gmail.com>

# -----------------------------------------------------------------------------
# Environment variables
# -----------------------------------------------------------------------------
ARG NODE_VERSION=12.18.0
ARG NPM_VERSION=latest
ARG IONIC_VERSION=5.2.7
ARG CORDOVA_VERSION=8.1.2

ARG GRADLE_VERSION=4.1
ENV ANDROID_VERSION=25

ARG ANDROID_BUILD_TOOLS_VERSION=25.2.5
ARG ANDROID_PLATFORMS="android-21 android-22 android-23 android-24 android-25"

ENV ANDROID_HOME /opt/android-sdk-linux
ENV GRADLE_HOME /opt/gradle
ENV PATH ${PATH}:${GRADLE_HOME}/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
ARG ANDROID_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip

# -----------------------------------------------------------------------------
# Pre-install
# -----------------------------------------------------------------------------
RUN \
  dpkg --add-architecture i386 \
  && apt-get update -y \
  && apt-get install -y \

    # tools
    curl \
    wget \
    zip \
    vim python3-venv python3-pip \
    git
    
# -----------------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------------

# Install Java
RUN apt-get install -y --no-install-recommends openjdk-8-jdk

# Install Node and NPM
RUN \
  apt-get update -qqy \
  && curl --retry 3 -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
  && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.gz" \
  && npm install -g npm@"$NPM_VERSION" \
  && npm install -g cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION"

# Download and install Gradle
RUN \
  cd /opt \
  && wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
  && unzip gradle*.zip \
  && ls -d */ | sed 's/\/*$//g' | xargs -I{} mv {} gradle \
  && rm gradle*.zip


# Download Android SDK\
RUN mkdir -p ${ANDROID_HOME} && cd "$ANDROID_HOME" \
	&& curl -o sdk.zip $ANDROID_TOOLS_URL \
	&& unzip sdk.zip -d ${ANDROID_HOME}/cmdline-tools \
	&& mv cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/tools \
	&& rm sdk.zip \
	&& mkdir -p "$ANDROID_HOME/licenses" || true \
	&& echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license" \
	&& sdkmanager --version \
	&& yes | sdkmanager --sdk_root=${ANDROID_HOME} --licenses \
	&& sdkmanager "platforms;android-${ANDROID_VERSION}" \
	&& sdkmanager "platform-tools" \
	&& sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

WORKDIR /project
EXPOSE 8100 35729 53703
CMD ionic serve

# -----------------------------------------------------------------------------
# Clean up
# -----------------------------------------------------------------------------
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*