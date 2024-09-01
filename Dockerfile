FROM ubuntu:20.04

ENV ANDROID_SDK_ROOT=/usr/lib/android-sdk/

RUN mkdir /home/miab
WORKDIR /home/miab/

# Install required packages
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get upgrade -y 
RUN apt-get -y install --no-install-suggests --no-install-recommends \
    git dos2unix p7zip lz4 \
    apt-utils apt-transport-https ca-certificates gnupg \
    python3 \
    android-sdk openjdk-21-jdk-headless openjdk-21-jre-headless \
    cargo curl \
    wget unzip g++

# Download Android commandlinetools and accept SDK licenses
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip 
RUN unzip commandlinetools-linux-9123335_latest.zip 
RUN mkdir --parents "$ANDROID_SDK_ROOT/cmdline-tools/latest" 
RUN mv cmdline-tools/* "$ANDROID_SDK_ROOT/cmdline-tools/latest/" && rm -r cmdline-tools/ commandlinetools-linux-9123335_latest.zip
ENV PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH 
RUN yes | sdkmanager --licenses

# Clone Magisk
RUN git clone --depth 1 --recurse-submodules https://github.com/topjohnwu/Magisk.git

# Copy Magisk in a Box script into container
COPY ./miab.sh .

WORKDIR /home/miab/Magisk

# Build Magisk
RUN python3 build.py ndk  
RUN python3 build.py stub 
RUN python3 build.py native magisk 
RUN python3 build.py native magiskboot 
RUN python3 build.py native magiskinit 

WORKDIR /home/miab/
RUN cp Magisk/scripts/boot_patch.sh . && cp Magisk/scripts/util_functions.sh .
