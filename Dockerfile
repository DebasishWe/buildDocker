# Use Ubuntu base image
FROM ubuntu:24.04

# Set environment variable to noninteractive to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install necessary packages including sudo
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils sudo && \
    apt upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Locale installation
RUN apt-get update && apt-get install -y locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8
 
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a new user named 'myuser' and give sudo access
RUN useradd -ms /bin/bash myuser && \
    echo 'myuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Switch to the new user
USER myuser

# Set the working directory
WORKDIR /home/myuser

# Install only sendmail as 'myuser'
RUN sudo apt-get update && \
    sudo apt-get install -y sendmail && \
    sudo apt-get clean

# Set full permissions on the working directory (if needed)
RUN sudo chmod -R 777 /home/myuser && \
    sudo chown -R myuser:myuser /home/myuser

# Install all packages
RUN sudo apt-get -y install nano xvfb xrdp ufw curl at wget gnupg git build-essential software-properties-common -qq -qqy apt-transport-https ca-certificates lxc iptables && \
    sudo systemctl enable xrdp && \
    sudo ufw allow 3389/tcp

# Install homebrew
RUN yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo >> /home/myuser/.bashrc && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/myuser/.bashrc && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Set environment variable for Homebrew
ENV HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
ENV PATH="$HOMEBREW_PREFIX/bin:$PATH"
RUN brew install gcc coreutils jq openjdk@17

RUN echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/openjdk@17/bin:$PATH"' >> ~/.profile && \
    export CPPFLAGS="-I/home/linuxbrew/.linuxbrew/opt/openjdk@17/include"
ENV CPPFLAGS="-I/home/linuxbrew/.linuxbrew/opt/openjdk@17/include"
ENV HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew/opt/openjdk@17
ENV PATH="$HOMEBREW_PREFIX/bin:$PATH"

RUN brew install awscli node git-lfs doctl ant gradle@7 sass/sass/sass && \
    echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/gradle@7/bin:$PATH"' >> ~/.profile
ENV GRADLE_PREFIX=/home/linuxbrew/.linuxbrew/opt/gradle@7
ENV PATH="$GRADLE_PREFIX/bin:$PATH"

# Setup containerd
RUN sudo install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    sudo chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
           https://download.docker.com/linux/ubuntu \
           $(lsb_release -cs) stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    sudo apt update && \
    sudo apt install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin

# # Install the magic wrapper.
ADD ./config/wrapdocker.sh /usr/local/bin/wrapdocker.sh
RUN sudo chmod +x /usr/local/bin/wrapdocker.sh
RUN sudo usermod -aG docker myuser
RUN newgrp docker

ARG HOME_DIR
ARG SPM_WORK_HOME="$HOME_DIR/work"
ENV HOME_DIR=/home/myuser
ENV SPM_WORK_HOME=$HOME_DIR/work
RUN echo $SPM_WORK_HOME
RUN echo 'export SPM_WORK_HOME=$HOME_DIR/work' >> ~/.profile

# Create the work directory and give ownership to the current user
RUN mkdir -p $HOME_DIR && \
    chown -R myuser:myuser $HOME_DIR

# # Change permissions to allow full access to mkdir without sudo
RUN mkdir $SPM_WORK_HOME
RUN . ~/.profile
RUN mkdir $SPM_WORK_HOME/dev 

# Set the working directory
WORKDIR $SPM_WORK_HOME/dev 

# Install google & firefox headless browsers
RUN sudo apt install -y chromium-browser firefox

# Copy in the dev init script
COPY config/dev-init.sh $SPM_WORK_HOME/dev/dev-init.sh
RUN . $SPM_WORK_HOME/dev/dev-init.sh

# Install mysql
RUN brew install mysql@8.0
ENV MYSQL_PREFIX=/home/linuxbrew/.linuxbrew/opt/mysql@8.0
ENV PATH="$MYSQL_PREFIX/bin:$PATH"
RUN echo 'export PATH="/home/linuxbrew/.linuxbrew/opt/mysql@8.0/bin:$PATH"' >> ~/.profile && \
    export LDFLAGS="-L/home/linuxbrew/.linuxbrew/opt/mysql@8.0/lib" && \
    export CPPFLAGS="-I/home/linuxbrew/.linuxbrew/opt/mysql@8.0/include"
ENV mysql=" /home/linuxbrew/.linuxbrew/opt/mysql@8.0/bin/mysqld_safe --datadir\=/home/linuxbrew/.linuxbrew/var/mysql"

# Copy the mysql config into the container
COPY config/my.cnf.template /usr/local/bin/my.cnf.template
COPY config/mysql-init.sh /usr/local/bin/mysql-init.sh
RUN sudo chmod +x /usr/local/bin/mysql-init.sh

# RUN sed -i 's/^bind-address/#bind-address/' /home/linuxbrew/.linuxbrew/etc/my.cnf && \
#     sed -i 's/^mysqlx-bind-address/#mysqlx-bind-address/' /home/linuxbrew/.linuxbrew/etc/my.cnf
ENV PROJ=$SPM_WORK_HOME/dev/projects

RUN /usr/local/bin/mysql-init.sh

# Change ownership and permissions for Gradle
RUN gradle -v && \
    sudo chown -R $(whoami) ~/.gradle && \
    sudo chmod -R 755 ~/.gradle

# remove unwanted packages   
RUN sudo apt autoremove

CMD ["bash"]

