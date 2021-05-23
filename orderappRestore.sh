#! bin/bash

#SCRIPT TO RESTORE THE CUSTOMER END APP (ORDERAPP) ON THE SECOND VM
#20210523

#1. CLEAN UP CONTAINERS AND IMAGES
sudo docker container prune --force
sudo docker image prune --force

#2. DELETE EXISTING APP
cd \mydocker
rm -R OrderApp

#5. CLONE THE CUSTOMER APP (ORDERAPP) TO THE VM AND MOVE FILES TO THE RIGHT LOCATIONS#>
git clone https://github.com/matty8salisbury/OrderApp.git
mv OrderApp/Dockerfile Dockerfile
cd
mv price_list.csv mydocker/OrderApp/price_list.csv
mv venueinfo.R mydocker/OrderApp/venueinfo.R
cd mydocker

#6. BUILD ORDERAPP DOCKER IMAGE, RUN AND EXIT VM1
sudo docker build -t customer_app .
sudo docker run -d -p 3838:3838 customer_app
