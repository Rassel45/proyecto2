FROM ubuntu:22.04

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

RUN useradd -ms /bin/bash dev

COPY startup.sh /bin/
COPY modprobe /bin/

RUN chmod +X /bin/startup.sh /bin/modprobe
VOLUME /var/lib/docker

EXPOSE 22
EXPOSE 8080

CMD ["usr/bin/supervisord"]