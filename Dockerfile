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

ARG ANDROID_BUILD_TOOLS_VERSION=25.0.3

ENV ANDROID_HOME /opt/android-sdk-linux
ENV GRADLE_HOME /opt/gradle
ENV PATH ${PATH}:${GRADLE_HOME}/bin
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/tools/bin
ENV PATH ${PATH}:${ANDROID_HOME}/platform-tools
ARG ANDROID_TOOLS_URL=https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip

USER root


# -----------------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------------


# Install Java
RUN apt-get update  \
 && apt-get install -y --no-install-recommends openjdk-8-jdk ca-certificates fontconfig locales unzip curl wget zip im python3-venv python3-pip git \
 && echo "root:admin" | chpasswd 

# Install Node and NPM
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash - &&\
  && sudo apt-get install -y nodejs
  # smoke tests
  && node --version \
  && npm --version  \
  && npm install -g npm@"$NPM_VERSION" \
  && npm install -g cordova@"$CORDOVA_VERSION" ionic@"$IONIC_VERSION" \
  && npm install -g cordova-res \
  && npm config set unsafe-perm true

# Download and install Gradle
RUN \
  cd /opt \
  && wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
  && unzip gradle*.zip \
  && ls -d */ | sed 's/\/*$//g' | xargs -I{} mv {} gradle \
  && rm gradle*.zip


# Download Android SDK
RUN mkdir -p ${ANDROID_HOME} && cd "$ANDROID_HOME" \
	&& curl -o sdk.zip $ANDROID_TOOLS_URL \
	&& unzip sdk.zip -d ${ANDROID_HOME}/cmdline-tools \
	&& mv cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/tools \
	&& rm sdk.zip \
	&& mkdir -p "$ANDROID_HOME/licenses" || true \
    && echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > "$ANDROID_HOME/licenses/android-sdk-license" \
    && echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > "$ANDROID_HOME/licenses/android-sdk-license" \
    && echo "d56f5187479451eabf01fb78af6dfcb131a6481e" > "$ANDROID_HOME/licenses/android-sdk-license" \
    && echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license" \
	&& sdkmanager --version \
	&& yes | sdkmanager --sdk_root=${ANDROID_HOME} --licenses \
	&& sdkmanager "platforms;android-${ANDROID_VERSION}" \
	&& sdkmanager "platform-tools" \
	&& sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

RUN chown -R root /usr/local/lib/node_modules/
WORKDIR /project
EXPOSE 8100 35729 53703
CMD ionic serve

# -----------------------------------------------------------------------------
# Clean up
# -----------------------------------------------------------------------------
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
