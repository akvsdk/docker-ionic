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
 && apt-get remove gpg \
 && apt-get install -y --no-install-recommends openjdk-8-jdk ca-certificates fontconfig locales unzip curl wget zip im python3-venv python3-pip git  gnupg dirmngr\
 && echo "root:admin" | chpasswd 

# Install Node and NPM
RUN set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
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
