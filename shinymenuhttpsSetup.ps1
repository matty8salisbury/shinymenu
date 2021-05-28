

#USER ASSUMED TO SET THE VENUE NAME DIRECTLY IN THE POWERSHELL
#$venue = "Bananaman1s_Bar_PE27_6TN"

#1. CREATE NGINX CONF FOR VENUE END

cd C:\shinymenu
$venueWeb = $venue.ToLower().Replace('_', '-')
if($venue.Length -gt 25) {$venueWeb = $venue.ToLower().Replace('_', '-').Substring(1, 25)}

Write-Host('venue web address: v'+$venueWeb+'.shinymenu.online')
Write-Host(" ")
Write-Host('customer web address: '+$venueWeb+'.shinymenu.online')


$textToUse = 'v'+$venueWeb
(Get-Content C:\shinymenu\shinymenuNginx.conf ).Replace("venueend", $textToUse) | Out-File -encoding utf8 -file C:\shinymenu\tmp.conf
Get-Content C:\shinymenu\tmp.conf -raw | % {$_ -replace "`r", ""} | Set-Content -NoNewline VenueShinymenuNginx.conf

#2. CREATE NGINX CONF FOR CUSTOMER END

(Get-Content C:\shinymenu\shinymenuNginx.conf ).Replace("venueend", $venueWeb) | Out-File -encoding utf8 -file C:\shinymenu\tmp.conf
Get-Content C:\shinymenu\tmp.conf -raw | % {$_ -replace "`r", ""} | Set-Content -NoNewline CustShinymenuNginx.conf

#3. COPY ACROSS NGINX CONFIG FOR VENUE END

$publicDns1 = aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].PublicDnsName[] | [0]"
$vmDestFile1 = "ubuntu@"+$publicDns1
$vmDestFile1 = $vmDestFile1.Replace('"','')
ssh -i "shinymenu_pair.pem" $vmDestFile1 'sudo certbot --nginx'
scp -i shinymenu_pair.pem VenueShinymenuNginx.conf ($vmDestFile1+':VenueShinymenuNginx.conf')
ssh -i "shinymenu_pair.pem" $vmDestFile1 'sudo mv VenueShinymenuNginx.conf /etc/nginx/sites-available/VenueShinymenuNginx.conf'
ssh -i "shinymenu_pair.pem" $vmDestFile1 'sudo ln -s /etc/nginx/sites-available/VenueShinymenuNginx.conf /etc/nginx/sites-enabled'
ssh -i "shinymenu_pair.pem" $vmDestFile1 'sudo nginx -t'
ssh -i "shinymenu_pair.pem" $vmDestFile1 'sudo systemctl restart nginx'

$publicDns2 = aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].PublicDnsName[] | [1]"
$vmDestFile2 = "ubuntu@"+$publicDns2
$vmDestFile2 = $vmDestFile2.Replace('"','')
ssh -i "shinymenu_pair.pem" $vmDestFile2 'sudo certbot --nginx'
scp -i shinymenu_pair.pem CustShinymenuNginx.conf ($vmDestFile2+':CustShinymenuNginx.conf')
ssh -i "shinymenu_pair.pem" $vmDestFile2 'sudo mv CustShinymenuNginx.conf /etc/nginx/sites-available/CustShinymenuNginx.conf'
ssh -i "shinymenu_pair.pem" $vmDestFile2 'sudo ln -s /etc/nginx/sites-available/CustShinymenuNginx.conf /etc/nginx/sites-enabled'
ssh -i "shinymenu_pair.pem" $vmDestFile2 'sudo nginx -t'
ssh -i "shinymenu_pair.pem" $vmDestFile2 'sudo systemctl restart nginx'

