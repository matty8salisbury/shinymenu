<##########################################################################>
<#DEPLOYMENT SCRIPT FOR SHINY MENU APPS                                   #>
<#PART 1                                                                  #>
<#VERSION 1                                                               #>
<#CREATED 20210513                                                        #>
<##########################################################################>

<##########################################################################>
<#BLOCK 1 : SET UP                                                        #>
<#SECTION FOR USER TO EDIT                                                #>
<#                                                                        #>
<#PLEASE EDIT TO CREATE YOUR PERSONALISED CREDENTIALS                     #>
<#                                                                        #>
$venue_name = "Matt1s_Bar"
$venue_display_name = "Matt's Bar"
$app_pswd = "mypassword"

$db_username = "replaceThisUsername"
$db_password = "replaceThisPassword"

<#END OF SECTION FOR USER TO EDIT##########################################>

<#CREATE shinymenu DIRECTORY AND MOVE TO IT#>
cd C:\
mkdir shinymenu
cd \shinymenu

<#2. CREATE VENUE INFORMATION R SCRIPT TO INPUT INTO APP AND SAVE INTO shinymenu#>
<#ASSUMES USER HAS ALREADY SET UP REQUIRED VENUE INFORMATION, PASSWORD AND SQL USERNAME AND PASSWORD#>

$exampleFile = @"
#SET REQUIRED PASSWORDS

#SET VENUE NAME AND VENUE DISPLAY NAME: 
#VENUE SHOULD BE THE VENUE NAME AND POSTCODE WITH ANY SPACES REPLACED BY _ AND ANY APOSTROPHES REPLACED BY 1
#VENUE DISPLAY TITLE SHOULD EXACTLY HOW THE CUSTOMER SHOULD SEE THE NAME

venue <<- "Bananaman1s_Bar_PE27_6TN"
venueDisplayTitle <<- "Bananaman's Bar"

#SQL database host, port, username and password

Sys.setenv(SQL_ENDPOINT = 'database-2.cnmaqhhd7kkj.eu-west-2.rds.amazonaws.com')
Sys.setenv(SQL_PORT = 3306)
Sys.setenv(MY_UID='sqlUsername')
Sys.setenv(MY_PWD='ReplaceThisPassword')

#VENUE LOGIN PASSWORD FOR PUBEND AND CHECKCLOSED APPS

Sys.setenv(VenuePsWd="BetterThanSuperTed001!")
"@

$exampleFile | Out-File -encoding utf8 -file C:\shinymenu\venueinfo.R

(Get-Content C:\shinymenu\venueinfo.R ).Replace('Bananaman1s_Bar_PE27_6TN',$venue_name) | Out-File -encoding utf8 -file C:\shinymenu\venueinfo.R
(Get-Content C:\shinymenu\venueinfo.R ).Replace("Bananaman's Bar", $venue_display_name) | Out-File -encoding utf8 -file C:\shinymenu\venueinfo.R
(Get-Content C:\shinymenu\venueinfo.R ).Replace("BetterThanSuperTed001!", $app_pswd) | Out-File -encoding utf8 -file C:\shinymenu\venueinfo.R
(Get-Content C:\shinymenu\venueinfo.R ).Replace("sqlUsername", $db_username) | Out-File -encoding utf8 -file C:\shinymenu\venueinfo.R
(Get-Content C:\shinymenu\venueinfo.R ).Replace("ReplaceThisPassword", $db_password) | Out-File -encoding utf8 -file C:\shinymenu\venueinfo.R

<#3. CREATE PRICE LIST TEMPLATE#>

$outfile = "C:\shinymenu\price_list.csv"
$newcsv = {} | Select "Item","Price","Section","Description" | Export-Csv $outfile
$csvfile = Import-Csv $outfile
$csvfile.Item = "Banana"
$csvfile.Price = "1"
$csvfile.Section = "Main"
$csvfile.Description = "The Original & Best!"
$csvfile | Export-CSV $outfile -NoTypeInformation


<#4. INSTALL AWS CLI TOOLS#>
Set-ExecutionPolicy RemoteSigned -Force
Install-Module -Name AWS.Tools.Installer -AllowClobber -Force
Install-AWSToolsModule AWS.Tools.EC2,AWS.Tools.S3 -CleanUp -AllowClobber -Force


<###########################################################################>
<#END OF BLOCK 1                                                           #>
<###########################################################################>


