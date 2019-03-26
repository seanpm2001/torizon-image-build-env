FROM ubuntu:16.04
MAINTAINER Andy Doan <andy@opensourcefoundries.com>

# bitbake requires a utf8 filesystem encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
ARG DEV_USER_NAME=Builder
ARG DEV_USER=builder
ARG DEV_USER_PASSWD=builder

# OSF PPA for additional dependencies and newer packages
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	   software-properties-common \
	&& add-apt-repository ppa:osf-maintainers/ppa \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		android-tools-fsutils ca-certificates chrpath cpio diffstat \
		file gawk g++ iproute2 iputils-ping less libmagickwand-dev \
		libmath-prime-util-perl libsdl1.2-dev libssl-dev locales \
		openjdk-9-jre openssh-client perl-modules python2.7 python-requests python3 \
		repo sudo texinfo vim-tiny wget whiptail libelf-dev curl\
	&& apt-get autoremove -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& locale-gen en_US.UTF-8

# Create the user which will run the SDK binaries.
RUN useradd -c $DEV_USER_NAME \
		-d /home/$DEV_USER \
		-G sudo,dialout,floppy,plugdev,users \
		-m \
		-s /bin/bash \
		$DEV_USER

# Add default password for the SDK user (useful with sudo)
RUN echo $DEV_USER:$DEV_USER_PASSWD | chpasswd

# Initialize development environment for $DEV_USER.
RUN sudo -u $DEV_USER -H git config --global credential.helper 'cache --timeout=3600'

# Merge

USER builder
WORKDIR /home/user

# Repo
RUN mkdir ~/bin && \ 
    curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo && \
    chmod a+x ~/bin/repo

# Torizon
RUN mkdir ~/torizon && \
    git config --global user.name username && \
    git config --global user.email you@email.com && \ 
    cd ~/torizon && ~/bin/repo init -u https://github.com/toradex/toradex-torizon-manifest -b master

ENV MACHINE $MACHINE

ENV TARGET $TARGET

COPY startup.sh .

USER root
RUN chmod 777 -R ./startup.sh

USER builder

CMD [ "/bin/bash", "-c" , "./startup.sh" ]
