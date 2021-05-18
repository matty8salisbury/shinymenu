#!/bin/bash

#SCRIPT TO RUN VENUE APP (PUBEND) ON EC2 INSTANCE
#20210515

#1. INSTALL DOCKER 
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update 
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo docker run hello-world

#2. INSTALL NGINX
sudo apt install nginx -y

#3. INSTALL CERTBOT
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

#4. CREATE DOCKER DIRECTORY AND CD INTO IT
mkdir mydocker 
cd \mydocker

#5. CLONE THE VENUE APP (PUBEND) TO THE VM AND MOVE FILES TO THE RIGHT LOCATIONS
git clone https://github.com/matty8salisbury/PubEnd.git
mv PubEnd/Dockerfile Dockerfile
cd
mv venueinfo.R mydocker/PubEnd/venueinfo.R
cd mydocker

#6.. BUILD PUBEND DOCKER IMAGE, RUN AND EXIT VM1
sudo docker build -t venue_apps .
sudo docker run -d -p 3838:3838 venue_apps


