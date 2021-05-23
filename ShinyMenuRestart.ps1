<####################################################################>
<#shinymenu.online restart script                                   #>
<#restarts the venue and customer apps after they have been stopped #>
<#assumes the instances have been re-started in the aws console     #>
<#20210523                                                          #>
<####################################################################>

<#1. CLEAR UP CONTAINERS AND IMAGES#>

cd C:\shinymenu

<#VM1#>
$publicDns1 = aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].PublicDnsName[] | [0]"
$vmDestFile1 = "ubuntu@"+$publicDns1
$vmDestFile1 = $vmDestFile1.Replace('"','')
ssh -i "shinymenu_pair.pem" $vmDestFile1 'sudo docker container prune --force'
ssh -i "shinymenu_pair.pem" $vmDestFile1 'sudo docker image prune --force'

<#VM2#>
$publicDns2 = aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].PublicDnsName[] | [1]"
$vmDestFile2 = "ubuntu@"+$publicDns2
$vmDestFile2 = $vmDestFile2.Replace('"','')
ssh -i "shinymenu_pair.pem" $vmDestFile2 'sudo docker container prune --force'
ssh -i "shinymenu_pair.pem" $vmDestFile2 'sudo docker image prune --force'

<#REPEAT THE STEPS FROM SET UP TO CLONE REPOS, BUILD IMAGES AND LAUNCH CONTAINERS#>

<#14. SECURE COPY THE VENUE INFORMATION TO THE FIRST INSTANCE, WHICH WILL BE USED FOR THE PUBEND APP#>
$vmDestFile1a = "ubuntu@"+$publicDns1+":venueinfo.R"
$vmDestFile1a = $vmDestFile1a.Replace('"','')
scp -o StrictHostKeyChecking=accept-new -i shinymenu_pair.pem venueinfo.R $vmDestFile1a

<#15. SECURE COPY THE VENUE INFORMATION TO THE FIRST INSTANCE, WHICH WILL BE USED FOR THE ORDERAPP#>
$vmDestFile2a = "ubuntu@"+$publicDns2+":venueinfo.R"
$vmDestFile2a = $vmDestFile2a.Replace('"','')
scp -o StrictHostKeyChecking=accept-new -i shinymenu_pair.pem venueinfo.R $vmDestFile2a
$vmDestFile2b = "ubuntu@"+$publicDns2+":price_list.csv"
$vmDestFile2b = $vmDestFile2b.Replace('"','')
scp -i shinymenu_pair.pem price_list.csv $vmDestFile2b

<#16. RUN BASH SCRIPT ON FIRST VM (EC2 INSTANCE) TO SET UP VENUE END APP (PUBEND)#>

#FIRST NEED TO CONVERT DOS ENDINGS TO UNIX AS GITHUB DELIVERS BASH SCRIPTS FORMATED FOR WINDOWS
Get-Content pubendRestore.sh -raw | % {$_ -replace "`r", ""} | Set-Content -NoNewline pubendRestoreUnixEndings.sh
Get-Content orderappRestore.sh -raw | % {$_ -replace "`r", ""} | Set-Content -NoNewline orderappRestoreUnixEndings.sh

$vmDestFile1 = "ubuntu@"+$publicDns1
$vmDestFile1 = $vmDestFile1.Replace('"','')
scp -i shinymenu_pair.pem pubendRestoreUnixEndings.sh ($vmDestFile1+':pubendRestore.sh')
ssh -i "shinymenu_pair.pem" $vmDestFile1 bash pubendRestore.sh

<#13. RUN BASH SCRIPT ON SECOND VM (EC2 INSTANCE) TO SET UP VENUE END APP (ORDERAPP)#>
$vmDestFile2 = "ubuntu@"+$publicDns2
$vmDestFile2 = $vmDestFile2.Replace('"','')
scp -i shinymenu_pair.pem orderappRestoreUnixEndings.sh ($vmDestFile2+':orderappRestore.sh')
ssh -i "shinymenu_pair.pem" $vmDestFile2 bash orderappRestore.sh

Set-ExecutionPolicy Restricted -Force