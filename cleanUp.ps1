#SHINYMENU ONLINE CLEAN UP CODE
#DELETES AWS INSTANCES, DATABASE, RELEASES ELASTIC IPS AND RESETS DEFAULT SECURITY GROUP INBOUND RULES

#1. DELETE DATABASE INSTANCE
$dbId = aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier' --output text
aws rds delete-db-instance --db-instance-identifier $dbId --skip-final-snapshot --delete-automated-backups  | Out-Null

#2. DELETE EC2 INSTANCES
$instanceIds = aws ec2 describe-instances --filters "Name=instance-state-name,Values=running, pending" --query "Reservations[*].Instances[*].InstanceId" --output text
aws ec2 terminate-instances --instance-ids $instanceIds

#3. DELETE KEY PAIRS
aws ec2 delete-key-pair --key-name MyKeyPair

#4. REVOKE SECURITY GROUP RULES
aws ec2 revoke-security-group-ingress --group-name default --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 revoke-security-group-ingress --group-name default --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 revoke-security-group-ingress --group-name default --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 revoke-security-group-ingress --group-name default --protocol tcp --port 3838 --cidr 0.0.0.0/0
aws ec2 revoke-security-group-ingress --group-name default --protocol tcp --port 3306 --cidr 172.31.0.0/16

#5. RELEASE ELASTIC IPS
#$sb = Start-Job -ScriptBlock{
#$var2 = aws ec2 describe-instances --filters "Name=instance-state-name,Values=running, pending" --query "Reservations[*].Instances[*].InstanceId | [0]"
#while($var2 -ne 'null') {
#$var2 = aws ec2 describe-instances --filters "Name=instance-state-name,Values=running, pending" --query "Reservations[*].Instances[*].InstanceId | [0]"
#Sleep 3
#}
#}
#Wait-Job $sb.Name

$elAlloc1 = aws ec2 describe-addresses --query 'Addresses[*].AllocationId[] | [0]'
$elAlloc2 = aws ec2 describe-addresses --query 'Addresses[*].AllocationId[] | [1]'

aws ec2 release-address --allocation-id $elAlloc1
aws ec2 release-address --allocation-id $elAlloc2

#6. DELETE FILES FROM C:\shinymenu FOLDER
Remove-Item 'C:\shinymenu\orderappSetupUnixEndings.sh'
Remove-Item 'C:\shinymenu\pubendSetupUnixEndings.sh'
Remove-Item 'C:\shinymenu\shinymenu_pair.pem'
Remove-Item 'C:\shinymenu\venueinfo.R'
Remove-Item 'C:\shinymenu\venueinfoPrep.R'

#7. RESET POWERSHELL PERMISSIONS
set-executionpolicy restricted -Force