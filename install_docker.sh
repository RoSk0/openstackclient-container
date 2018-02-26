#!/usr/bin/env bash

#=============================================================================
# A very basic script to do a vanilla docker installation in Ubuntu
# This script currently has no error handling at this time and is intended
# to be more of a guide as to the steps required to install Docker
#=============================================================================

# ensure that repository info is up to date
sudo apt-get update

# install some pre-requisite packages
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# retrieve the docker repository gpg key and install
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

# add the docker repository to available repos
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# ensure that repository info is up to date
sudo apt-get update

# install a vanilla docker version
sudo apt-get install docker-ce

# confirm the installation by running the simple docker 'hello world' example
sudo docker run hello-world

# add the current user to the docker group
sudo usermod -aG docker ${USER}

# update users id with new group - removes the need to logout to detect the change
newgrp docker
