FROM ubuntu:22.04

RUN apt update \
    && apt install -y ca-certificates openssh-client \
    wget curl iptables supervisor \
    && rm -rf /var/lib/apt/list/*

ENV DOCKER_CHANNEL=stable \
	DOCKER_VERSION=20.10.23 \
	DOCKER_COMPOSE_VERSION=2.15.1 \
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
RUN curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose && docker-compose version


RUN update-alternatives --set iptables /usr/sbin/iptables-legacy && \
	update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
ARG language=ca_ES

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

    
#layer cleanup script
COPY resources/scripts/*.sh  /usr/bin/
RUN chmod +x usr/bin/*.sh


RUN \
    mkdir -p $RESOURCES_PATH && chmod a+rwx $RESOURCES_PATH && \
    mkdir -p $SSL_RESOURCES_PATH && chmod a+rwx $SSL_RESOURCES_PATH && \
    mkdir -p /etc/supervisor /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor /var/logs /var/run/supervisor

RUN \
    if [ "$language" != "en_US" ]; then \
        apt-get -y update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales; \
        echo "${language}.UTF-8 UTF-8" > /etc/locale.gen; \
        locale-gen; \
        dpkg-reconfigure --frontend=noninteractive locales; \
        update-locale LANG="${language}.UTF-8"; \
    fi \
    && clean-layer.sh

RUN \
  apt update -y && \
  if ! which gpg; then \
       apt-get install -y --no-install-recommends gnupg; \
  fi; \
  clean-layer.sh


#Program install
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
  clean-layer.sh 


RUN \
    apt update -y && \
    apt install -y supervisor openssh-server apache2 mariadb-server && \
    clean-layer.sh


#We install the services needed
RUN apt-get update && apt-get install -y \
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

# SSH conf
RUN mkdir /var/run/sshd \ 
RUN echo 'root:root' | chpasswd 
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config 

# SSH login conf
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

#Install VS Code
RUN apt-get update && apt-get install -y curl gpg
RUN curl https://code.visualstudio.com/docs/?dv=linux64_deb && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    rm microsoft.gpg
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
RUN apt-get update && apt-get install -y code
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN curl -fsSL https://code-server.dev/install.sh | sh


# install Github and Gitlab
RUN apt-get update && apt-get install -y git && \
    curl -LJO https://github.com/github/hub/releases/download/v2.14.2/hub-linux-amd64-2.14.2.tgz && \
    tar xvzf hub-linux-amd64-2.14.2.tgz && \
    cd hub-linux-amd64-2.14.2 && \
    ./install && \
    cd ../ && \
    rm -rf hub-linux-amd64-2.14.2 && \
    rm hub-linux-amd64-2.14.2.tgz


# Install OpenSSL
RUN apt-get update && apt-get install -y openssl

# Install Python 3 and pip
RUN apt-get update && apt-get install -y python3 python3-pip
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Nodejs and npm
RUN apt-get install -y nodejs && \
    apt-get install -y npm

# Install Docker client
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-get update && apt-get install -y docker-ce-cli


# Install el MySQL client
RUN apt-get update && apt-get install -y mysql-client

#Mysql conf
ENV MYSQL_ROOT_PASSWORD=paulejo
ENV MYSQL_DATABASE=bbdduniversitat
ENV MYSQL_USER=dev
ENV MYSQL_PASSWORD=dev_password


COPY startup.sh /usr/local/bin/

COPY logger.sh /opt/bash-utils/logger.sh 

# Install Maven
RUN apt-get update && apt-get install -y maven

# Install Gradle
RUN apt-get update && apt-get install -y gradle


VOLUME /home/dev


VOLUME /var/lib/docker


VOLUME /var/run/docker.sock


EXPOSE 8081 3306 9001 443 80


EXPOSE 2222


COPY supervisord.conf /etc/supervisor
RUN chmod +x /usr/local/bin/startup.sh /usr/local/bin/modprobe
COPY docker-compose.yml /etc/docker-compose

CMD ["/usr/sbin/sddd", "-D"]
CMD ["/usr/local/bin/startup.sh"]
CMD ["tail", "-f", "/dev/null"]
