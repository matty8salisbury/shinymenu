<##########################################################################>
<#DEPLOYMENT SCRIPT FOR SHINY MENU APPS                                   #>
<#PART 2                                                                  #>
<#VERSION 1                                                               #>
<#CREATED 20210513                                                        #>
<##########################################################################>


<###########################################################################>
<#BLOCK 2: AMAZON WEB SERVICES SECTION                                     #>
<###########################################################################>

<#NEXT STEPS ASSUME PROFILE OF USER HAS ALREADY BEEN CONFIGURED USING FOLLOWING LINE#>
<#aws configure --profile shinymenuUser#>

<#1. SET CREDENTIALS FOR CURRENT AWS SESSION#>
set AWS_Profile shinymenuUser

<#2. INSTALL AWS CLI TOOLS - REMOVED AS NOW IN PART 1#>
#Set-ExecutionPolicy RemoteSigned -AllowClobber -Force
#Install-Module -Name AWS.Tools.Installer -Force
#Install-AWSToolsModule AWS.Tools.EC2,AWS.Tools.S3 -CleanUp -AllowClobber -Force

<#3. GET VCP ID#>
$vpcId4use = aws ec2 describe-vpcs --query 'Vpcs[*].VpcId[] | [0]'

<#4. GET SUBNET IDS FOR USE LATER#>
$subnetId4use1 = aws ec2 describe-subnets --query 'Subnets[*].SubnetId[] | [0]'
$subnetId4use2 = aws ec2 describe-subnets --query 'Subnets[*].SubnetId[] | [1]'
$subnetId4use3 = aws ec2 describe-subnets --query 'Subnets[*].SubnetId[] | [2]'

<#5. CREATE A KEY PAIR#>
aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text | out-file -encoding ascii -filepath C:\shinymenu\shinymenu_pair.pem

<#6. SET PORTS FOR SECURITY GROUP#>

$sgId4use = aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupId][] | [0]'

aws ec2 authorize-security-group-ingress --group-name default --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name default --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name default --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name default --protocol tcp --port 3838 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name default --protocol tcp --port 3306 --cidr 172.31.0.0/16

<#7A. CREATE INSTANCE 1, FOR PUBEND APP#>
aws ec2 run-instances --image-id ami-0194c3e07668a7e36 --count 1 --instance-type t2.micro `
    --key-name MyKeyPair --subnet-id $subnetId4use1 `
    --tag-specifications 'ResourceType=instance,Tags=[{Key=app-name,Value=pub-end}]' | Out-Null

<#7B. CREATE INSTANCE 2, FOR CUSTOMER APP#>
aws ec2 run-instances --image-id ami-0194c3e07668a7e36 --count 1 --instance-type t2.micro `
    --key-name MyKeyPair --subnet-id $subnetId4use1 `
    --tag-specifications 'ResourceType=instance,Tags=[{Key=app-name,Value=cus-end}]' | Out-Null

<#7C. STORE INSTANCE IDS#>
$instanceId1 = aws ec2 describe-instances  --query "Reservations[*].Instances[*].InstanceId[] | [0]"
$instanceId2 = aws ec2 describe-instances  --query "Reservations[*].Instances[*].InstanceId[] | [1]"

<#8. ALLOCATE 2 ELASTIC IP AND STORE#>
aws ec2 allocate-address
aws ec2 allocate-address

$elAlloc1 = aws ec2 describe-addresses --query 'Addresses[*].AllocationId[] | [0]'
$elAlloc2 = aws ec2 describe-addresses --query 'Addresses[*].AllocationId[] | [1]'
$elIp1 = aws ec2 describe-addresses --query 'Addresses[*].PublicIp[] | [0]'
$elIp2 = aws ec2 describe-addresses --query 'Addresses[*].PublicIp[] | [1]'

$publicDns1 = aws ec2 describe-instances  --query "Reservations[*].Instances[*].PublicDnsName[] | [0]"
$publicDns2 = aws ec2 describe-instances  --query "Reservations[*].Instances[*].PublicDnsName[] | [1]"

<#9. ASSOCIATE ELASTIC IPS TO INSTANCES#>
aws ec2 associate-address --instance-id $instanceId1 --allocation-id $elAlloc1
aws ec2 associate-address --instance-id $instanceId2 --allocation-id $elAlloc2

<#10. CREATE A SUBNET GROUP FOR RDS#>

aws docdb create-db-subnet-group `
    --db-subnet-group-description "subnet group for shinymenu database" `
    --db-subnet-group-name shinymenu-subnet-group `
    --subnet-ids $subnetId4use1 $subnetId4use2 $subnetId4use3

<#11. CREATE RDS MYSQL DATABASE#>

aws rds create-db-instance `
    --engine mysql `
    --db-instance-identifier shinymenudb `
    --allocated-storage 20 `
    --db-instance-class db.t2.micro `
    --vpc-security-group-id $sgId4use `
    --db-subnet-group shinymenu-subnet-group `
    --master-username $db_username `
    --master-user-password $db_password `
    --backup-retention-period 1 `
    --publicly-accessible

<#12. STORE SQL ENDPOINT#>
$sql_endpoint = aws rds describe-db-instances --query 'DBInstances[*].Endpoint[].Address | [0]'
(Get-Content C:\shinymenu\venueinfo.R ).Replace("'database-2.cnmaqhhd7kkj.eu-west-2.rds.amazonaws.com'", $sql_endpoint) | Out-File -encoding utf8 -file C:\shinymenu\venueinfo.R

<#FINISHED WITH AWS COMMANDS AND NOW TRANSFERRING DATA TO VMS AND SETTING UP APPS ON VMS        #>

<#13. RESET KEY PERMISSIONS SO THEY CAN BE SECURE COPIED ONTO VIRTUAL MACHINES (EC2 INSTANCES)#>
#reset permissions to ensure able to log in to server using keys
# Source: https://stackoverflow.com/a/43317244
$path = ".\shinymenu_pair.pem"
# Reset to remove explict permissions
icacls.exe $path /reset
# Give current user explicit read-permission
icacls.exe $path /GRANT:R "$($env:USERNAME):(R)"
# Disable inheritance and remove inherited permissions
icacls.exe $path /inheritance:r

<#14. SECURE COPY THE VENUE INFORMATION TO THE FIRST INSTANCE, WHICH WILL BE USED FOR THE PUBEND APP#>
$vmDestFile1a = "ubuntu@"+$publicDns1+":venueinfo.R"
$vmDestFile1a = $vmDestFile1a.Replace('"','')
scp -i shinymenu_pair.pem venueinfo.R $vmDestFile1a

<#15. SECURE COPY THE VENUE INFORMATION TO THE FIRST INSTANCE, WHICH WILL BE USED FOR THE ORDERAPP#>
$vmDestFile2a = "ubuntu@"+$publicDns2+":venueinfo.R"
$vmDestFile2a = $vmDestFile2.Replace('"','')
scp -i shinymenu_pair.pem venueinfo.R $vmDestFile2a
$vmDestFile2b = "ubuntu@"+$publicDns2+":venueinfo.R"
$vmDestFile2b = $vmDestFile2b.Replace('"','')
scp -i shinymenu_pair.pem price_list.csv $vmDestFile2b

<#16. RUN BASH SCRIPT ON FIRST VM (EC2 INSTANCE) TO SET UP VENUE END APP (PUBEND)

$vmDestFile1 = "ubuntu@"+$publicDns1
$vmDestFile1 = $vmDestFile1.Replace('"','')
scp -i shinymenu_pair.pem pubendSetup.sh ($vmDestFile1+':pubendSetup.sh')
ssh -i "shinymenu_pair.pem" $vmDestFile1 bash pubendSetup.sh

<#13. RUN BASH SCRIPT ON SECOND VM (EC2 INSTANCE) TO SET UP VENUE END APP (ORDERAPP)

$vmDestFile2 = "ubuntu@"+$publicDns2
$vmDestFile2 = $vmDestFile2.Replace('"','')
scp -i shinymenu_pair.pem orderappSetup.sh ($vmDestFile2+':orderappSetup.sh')
ssh -i "shinymenu_pair.pem" $vmDestFile2 bash orderappSetup.sh

$WebToOpen1 = 'http:\\'+$elIp1.Replace('"','')+':3838'
$WebToOpen2 = 'http:\\'+$elIp2.Replace('"','')+':3838'

start $WebToOpen1
start $WebToOpen2

<###########################################################################>
<#END OF BLOCK 2                                                           #>
<###########################################################################>