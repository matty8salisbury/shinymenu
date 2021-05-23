#!/bin/bash

#SCRIPT TO RESTORE VENUE APP (PUBEND) ON EC2 INSTANCE
#20210523

#1. CLEAR UP DOCKER CONTAINERS AND IMAGES
sudo docker container prune --force
sudo docker image prune --force

#2. CLEAR PUBAPP
cd \mydocker
rm -R PubEnd

#5. CLONE THE VENUE APP (PUBEND) TO THE VM AND MOVE FILES TO THE RIGHT LOCATIONS
git clone https://github.com/matty8salisbury/PubEnd.git
cd
mv venueinfo.R mydocker/PubEnd/venueinfo.R
cd mydocker

#6.. BUILD PUBEND DOCKER IMAGE, RUN AND EXIT VM1
sudo docker build -t venue_apps .
sudo docker run -d -p 3838:3838 venue_apps


