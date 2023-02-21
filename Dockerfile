FROM ubuntu:22.04

RUN apt update \
    && apt install -y ca-certificates openssh-client \
    wget curl iptables supervisor \
    && rm -rf /var/lib/apt/list/*
RUN apt install -y curl
ENV DOCKER_CHANNEL=stable \
	DOCKER_VERSION=20.10.23 \
	DOCKER_COMPOSE_VERSION=3.3 \
	DEBUG=false

# Docker installation
RUN set -eux; \
	\
	arch="$(uname --m)"; \
	case "$arch" in \
        # amd64
		x86_64) dockerArch='x86_64' ;; \
        # arm32v6
		armhf) dockerArch='armel' ;; \
        # arm32v7
		armv7) dockerArch='armhf' ;; \
        # arm64v8
		aarch64) dockerArch='aarch64' ;; \
		*) echo >&2 "error: unsupported architecture ($arch)"; exit 1 ;;\
	esac; \
	\
	if ! wget -O docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/${dockerArch}/docker-${DOCKER_VERSION}.tgz"; then \
		echo >&2 "error: failed to download 'docker-${DOCKER_VERSION}' from '${DOCKER_CHANNEL}' for '${dockerArch}'"; \
		exit 1; \
	fi; \
	\
	tar --extract \
		--file docker.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
	; \
	rm docker.tgz; \
	\
	dockerd --version; \
	docker --version

COPY modprobe startup.sh /usr/local/bin/
COPY supervisor/ /etc/supervisor/conf.d/
COPY logger.sh /opt/bash-utils/logger.sh

RUN chmod +x /usr/local/bin/startup.sh /usr/local/bin/modprobe
VOLUME /var/lib/docker

# Docker compose installation
RUN curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose && docker-compose version


RUN update-alternatives --set iptables /usr/sbin/iptables-legacy && \
	update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

RUN \ 
  apt update -y && \ 
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  build-essential \
  software-properties-common \
  libcurl4 \
  curl \
  apt-utils \
  ssh \
  gradle \
  maven \
  nodejs \
  openssl \
  vim \
  bash-completion \
  iputils-ping \
  npm \
  wget \
  openssl \
  git \
  zip \
  gzip \
  unzip \
  bzip2 \
  lzop \
  sudo && \
  clean-layer.sh \
  supervisor \
  openssh-server \
  python3 \
  python3-pip \
  nodejs \
  npm \
  #sdkman \
  docker.io \
  docker-compose \
  mysql-client \
  git \
  #github-cli \
  maven \
  gradle
RUN \
    apt update -y && \
    apt install -y supervisor openssh-server apache2 mariadb-server && \
    clean-layer.sh
ENV DOCKER_CHANNEL=stable \
	DOCKER_VERSION=20.10.23 \
	DOCKER_COMPOSE_VERSION=3.3 \
	DEBUG=false
ENV \
    USER=alumne \
    PASSWORD=alumne \
    LANG="${language}.UTF-8" \
    LC_CTYPE="${language}.UTF-8" \
    LC_ALL="${language}.UTF-8" \
    LANGUAGE="${language}:ca" \
    REMOVE_DASH_LINECOMMENT=true \
    SHELL=/bin/bash 
ENV \
    HOME="/home/$USER" \
    DEBIAN_FRONTEND="noninteractive" \
    RESOURCES_PATH="/resources" \
    SSL_RESOURCES_PATH="/resources/ssl"
ENV \
    WORKSPACE_HOME="${HOME}" \
    MYSQL_ALLOW_EMPTY_PASSWORD=true \
    MYSQL_USER="$USER" \ 
    MYSQL_PASSWORD="$PASSWORD"

# ssh configuration needed for it to work.
RUN mkdir /var/run/sshd \ 
RUN echo 'root:root' | chpasswd 
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN echo "export VISIBLE=now" >> /etc/profile
#install vs code
RUN apt-get update && apt-get install -y curl gpg
RUN curl https://code.visualstudio.com/docs/?dv=linux64_deb && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    rm microsoft.gpg
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
RUN apt-get update && apt-get install -y code
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl -fsSL https://code-server.dev/install.sh | sh
#Install all of git (github & gitlab)
RUN apt-get install -y git && \
    curl -LJO https://github.com/github/hub/releases/download/v2.14.2/hub-linux-amd64-2.14.2.tgz && \
    tar xvzf hub-linux-amd64-2.14.2.tgz && \
    cd hub-linux-amd64-2.14.2 && \
    ./install && \
    cd ../ && \
    rm -rf hub-linux-amd64-2.14.2 && \
    rm hub-linux-amd64-2.14.2.tgz

#openssl install
RUN apt-get install -y openssl

# Python 3 and pip install
RUN apt-get install -y python3 python3-pip
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#nodejs and npm install
RUN apt-get install -y nodejs && \
    apt-get install -y npm
#docker client install
RUN aapt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-get install -y docker-ce-cli

#mysql client install
RUN  apt-get install -y mysql-client
#And configuration too
ENV MYSQL_ROOT_PASSWORD=dev
ENV MYSQL_DATABASE=bbdev
ENV MYSQL_USER=dev
ENV MYSQL_PASSWORD=dev
#Install maven
RUN apt-get install -y maven
#install gradle
RUN apt-get install -y gradle

VOLUME /home/dev
VOLUME /var/lib/docker
VOLUME /var/run/docker.sock

EXPOSE 3306 3000 8091 2222 443 9001 80

ENTRYPOINT ["startup.sh"]

CMD ["/usr/sbin/sddd", "-D"]
CMD ["/usr/local/bin/startup.sh"]
CMD ["tail", "-f", "/dev/null"]
