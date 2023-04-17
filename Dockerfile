#We take an ubuntu image as a base
FROM ubuntu:22.04
#We install the necessary for dev to work as we want
RUN \
    apt update \
    && apt install -y ca-certificates openssh-client \
    npm \
    supervisor \
    maven \
    zip \
    ssh \
    gradle \
    nodejs \
    curl \
    wget curl iptables \
    git \
    python3 \
    python3-pip \
    mysql-client \
    && apt upgrade -y && curl -s "https://get.sdkman.io" | bash \
    && apt install docker-compose -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*
#Adds an user called 'dev'
RUN useradd -ms /bin/bash dev
#here we copy the startup.sh and modprobe we have in the folder into the image
COPY startup.sh /bin/
COPY modprobe /bin/
#and for it to work properly it needs permissions
RUN chmod +X /bin/startup.sh /bin/modprobe
VOLUME /var/lib/docker
#Open the ports 22 and 8080
EXPOSE 22
EXPOSE 8080
#Runs on supervisord
CMD ["usr/bin/supervisord"]
