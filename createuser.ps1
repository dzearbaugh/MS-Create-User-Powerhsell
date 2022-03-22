#******************************************************************************************************************************** 
# ACCOUNT CREATION AUTOMATION
# 
# Meant to completely automate account setup and onboarding for institution. 
# Involves AD, MS Licenses, Email, Signature, DLs, Additional Mailbox Permissions, Intranet, & Teams.
#
# This powershell script works specifically for a physical AD Server with replication to Office 365. 
# Differing setup may require changes to the powershell.
# 
# *******************************************************************************************************************************
# By David Zearbaugh - 3/22/2022
#
# Original script by Josh McMullin - 
# https://community.spiceworks.com/topic/2249950-powershell-automate-user-and-mailbox-creation
#********************************************************************************************************************************
#
# IMPORTANT! UPDATE STEPS A, B, & C PRIOR TO ATTEMPTING RUN
# 
#********************************************************************************************************************************
# A. PREREQUISITES - WHAT YOU NEED PRIOR TO RUNNING
# B. VARIIABLE SETUP - ENTER INSTITUTIONAL DATA
# C. SECTIONS TO UPDATE - YOU NEED TO UPDATE THESE BEFORE RUNNING
#********************************************************************************************************************************
# 
# USER CREATION POWERSHELL DOES THE FOLLOWING:
#
# SECTION 1 -  Conenction to Modules
# SECTION 2 -  Collects Necessary Data
# SECTION 2A - Collects AD Data
# SECTION 2B - Collects Distribution List Data
# SECTION 2C - Collects Additional Mailbox Data
# SECTION 2D - Collects Teams Data
# SECTION 3 -  Creates User in AD
# SECTION 4 -  Adds Licensing to Account
# SECTION 5 -  Copies Signature over from Standard User
# SECTION 6 -  Adds User to Necessary Distribution Lists
# SECTION 7 -  Gives Option to Add Mailbox Access (View Mailboxes Only)
# SECTION 8 -  Adds User to Intranet
# SECTION 9 -  Adds User to Teams
# SECTION 10 - Disconnecting from Modules
# SECTION 11 - Printing New User Information
# 
#********************************************************************************************************************************
<#
*************************************************************************************
A. PREREQUISITES
*************************************************************************************

1. Always Open & Run Windows Powershell ISE as Administrator
2. Ensure you have installed the following required modules
    A. Install-Module -Name ExchangeOnlineManagement
    B. Install-Module -Name MicrosoftTeams
    C. Install-Module -Name Microsoft.Online.SharePoint.PowerShell
    D. Install-ADServiceAccount (can't recall if this one is necessary)
3. Update VARIABLE SETUP below with appropriate data for variables from your institution
4. Review SECTIONS TO UPDATE and make appropriate changes prior to running

#>
<#
*************************************************************************************
B. VARIABLE SETUP - ENTER INSTITUTIONAL DATA HERE PRIOR TO RUNNING
*************************************************************************************
#>
#Add your information here to the variables in order for all the pieces to work

#Set Domain (for email and a few other things)
$Domain = "@yourcompanydomain.com"

#Search Base for Get-ADOrganizationalUnit should look something like:
#Example "OU=Users,DC=google,DC=local"
$SearchBase = "OU=Users,DC=google,DC=local"

#Security Group
#If you need to add more security groups, add new variables below and lines near the end of Section 3 from Add-ADGroupMember command
$SecurityGroup1 = "Enter Security Group Name Here"

#Microsoft Licenses
#Get License Informatoin from Get-MsolAccountSku command
#If you need to add more or remove licenses, do so from Section 4
$License1 = "Enter License Information Here"
$License2 = "Enter License Information Here"

#Signature
#This variable is used to copy from the signature from a user to the new user who is being created
$BorrowUserSignature = "user@yourcompanydomain.com"

#Email Body Settings
$DefaultFontName = "Arial" 
$DefaultFontSize = "11"

#Standard DLs for All Users
#If you need to add more security groups, add new variables below and lines in Section 6
$standarddl1 = "Enter DL Name Here"
$standarddl2 = "Enter DL Name Here"

#Intranet
#Intranet URL
$IntranetSiteURL = "https://yourcompany.sharepoint.com/"
$IntranetSiteAdminURL = "https://yourcompany-admin.sharepoint.com/"
#For adding users to MS Intranet as member
#Intranet Group Name
#May need to be changed if your Intranet groups are different
$intranetgroup = "Intranet Members"

#Teams Group ID
#Can be found by going to https://admin.teams.microsoft.com/teams/manage, finding the appropriate team, and copying the Group ID
$TeamsGroupId = "Add Teams Group ID Here"
<#
*************************************************************************************
C. SECTIONS TO UPDATE
*************************************************************************************

1. $setaddress in SECTION 2A - Add/Remove/Update Address Information Settings
2. $setDepartment in SECTION 2A - Add/Remove/Update Department Information Settings

#>

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 1 - SETTING UP CONNECTIONS"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Making sure we can run the setup
Set-ExecutionPolicy RemoteSigned -Force -Scope CurrentUser

#Getting Credentials to do all the work
$UserCredential = Get-Credential -Message "For Username Below, Enter Email Address!"

#FOR MOST OF THE SECTIONS
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -Credential $UserCredential
Connect-MsolService -Credential $UserCredential

#SECTION 8 - INTRANET ACCCESS
Connect-SPOService -Url $IntranetSiteAdminURL -Credential $UserCredential

#SECTION 9 - TEAMS
Connect-MicrosoftTeams -Credential $UserCredential

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 2 - COLLECTING DATA - STARTING"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 2A - COLLECTING AD DATA"
Write-Host "*******************************************************************"
Write-Host  "`n"

# Acquiring name data
$GivenName = Read-Host "Enter new user's first name - example John"
$Surname = Read-Host "Enter new user's last name - example Smith"

#Set user default password
$defpassword = Read-Host "Enter Default New User Password Here"

#Make default password secure string
$defpassword = (ConvertTo-SecureString $defpassword -AsPlainText -force)

#Making the Address Entry Easier
$setaddress = Read-Host "Location? 
1 = First Location 
2 = Second Location
"

if($setaddress -eq 1){
   $Company = "Company Name"
   $Office = ""
   $StreetAddress = "Number Stree"
   $City = "City" 
   $State = "2 Digit State"
   $PostCode = "Zip Code"
   $Country = "United States"
} 
elseif($setaddress -eq 2) {
   $Company = "Company Name"
   $Office = ""
   $StreetAddress = "Number Stree"
   $City = "City" 
   $State = "2 Digit State"
   $PostCode = "Zip Code"
   $Country = "United States"
}
else {
   $Company = "Company Name"
   $Office = ""
   $StreetAddress = "Number Stree"
   $City = "City" 
   $State = "2 Digit State"
   $PostCode = "Zip Code"
   $Country = "United States"
}

#Process that derives the username from the First initial of Given + Surname
#Username will be be JSmith or JoSmith or JohSmith or JohnSmith depending on match below
$SAMAccountName = $GivenName.Substring(0,1) + $Surname

#Ensures Unique User Name

if(Get-ADUser -Filter "samaccountname -eq '$samaccountname'"){
    $SAMAccountName = $GivenName.Substring(0,2) + $Surname
    if(Get-ADUser -Filter "samaccountname -eq '$samaccountname'"){
    $SAMAccountName = $GivenName.Substring(0,3) + $Surname
    if(Get-ADUser -Filter "samaccountname -eq '$samaccountname'"){
    $SAMAccountName = $GivenName.Substring(0,4) + $Surname
        }
    }
}

# Converts the samaccountname to lower case
$SAMAccountLower = $SAMAccountName.ToLower()

#Creates the display name
$DisplayName = $GivenName + " " + $Surname

#Office Information
$Title = Read-Host "Enter new users Title - example Clerk I"
$setDepartment = Read-Host "Enter Department number: 
1 - First Department 
2 - Second Department
3 - Third Department
4 - Fourth Department
5 - Fifth Department
6 - Sixth Department 
7 - Seventh Department
8 - Eighth Department

Number?"
if($setDepartment -eq 1){
   $Department = "First Department"
   }
elseif($setDepartment -eq 2){
   $Department = "Second Department"
   }
elseif($setDepartment -eq 3){
   $Department = "Third Department"
   }
elseif($setDepartment -eq 4){
   $Department = "Fourth Department"
   }
elseif($setDepartment -eq 5){
   $Department = "Fifth Department"
   }
elseif($setDepartment -eq 6){
   $Department = "Sixth Department"
   }
elseif($setDepartment -eq 7){
   $Department = "Seventh Department"
   }
elseif($setDepartment -eq 8){
   $Department = "Eighth Department"
   }
else{
   $Department = ""
}
$Phone = Read-Host "Enter new users office phone number"
$ManagerInput = Read-Host "Enter Manager Username"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 2B - COLLECTING DISTRIBUTION LIST DATA"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Show DLs to help with adding
Get-DistributionGroup | Format-Table primarysmtpaddress

#Add DLs  - Up to 9
Write-Host "This section does not give user send as permission. Only access to view email account
Update permissions if you need them to have send as permissions."
$adddls = Read-Host "How many additional DLs do you want to add the user to (0-9)?"
if ($adddls -eq 1){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2,$dl3,$dl4,$1dl5,$dl6,$dl7,$dl8,$dl9 = $null
}
elseif ($adddls -eq 2){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3,$dl4,$dl5,$dl6,$dl7,$dl8,$dl9 = $null
}
elseif ($adddls -eq 3){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl3 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3 = $dl3 + $Domain
$dl4,$dl5,$dl6,$dl7,$dl8,$dl9 = $null
}
elseif ($adddls -eq 4){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl3 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl4 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3 = $dl3 + $Domain
$dl4 = $dl4 + $Domain
$dl5,$dl6,$dl7,$dl8,$dl9 = $null
}
elseif ($adddls -eq 5){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl3 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl4 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl5 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3 = $dl3 + $Domain
$dl4 = $dl4 + $Domain
$dl5 = $dl5 + $Domain
$dl6,$dl7,$dl8,$dl9 = $null
}
elseif ($adddls -eq 6){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl3 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl4 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl5 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl6 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3 = $dl3 + $Domain
$dl4 = $dl4 + $Domain
$dl5 = $dl5 + $Domain
$dl6 = $dl6 + $Domain
$dl7,$dl8,$dl9 = $null
}
elseif ($adddls -eq 7){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl3 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl4 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl5 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl6 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl7 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3 = $dl3 + $Domain
$dl4 = $dl4 + $Domain
$dl5 = $dl5 + $Domain
$dl6 = $dl6 + $Domain
$dl7 = $dl7 + $Domain
$dl8,$dl9 = $null
}
elseif ($adddls -eq 8){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl3 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl4 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl5 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl6 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl7 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl8 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3 = $dl3 + $Domain
$dl4 = $dl4 + $Domain
$dl5 = $dl5 + $Domain
$dl6 = $dl6 + $Domain
$dl7 = $dl7 + $Domain
$dl8 = $dl8 + $Domain
$dl9 = $null
}
elseif ($adddls -eq 9){
$dl1 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl2 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl3 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl4 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl5 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl6 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl7 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl8 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl9 = Read-Host "Additional DL that you want to add them to? Username only - I'll add the domain"
$dl1 = $dl1 + $Domain
$dl2 = $dl2 + $Domain
$dl3 = $dl3 + $Domain
$dl4 = $dl4 + $Domain
$dl5 = $dl5 + $Domain
$dl6 = $dl6 + $Domain
$dl7 = $dl7 + $Domain
$dl8 = $dl8 + $Domain
$dl9 = $dl9 + $Domain
}
else{
$dl1,$dl2,$dl3,$dl4,$dl5,$dl6,$dl7,$dl8,$dl9 = $null
}

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 2C - COLLECTING ADDITIONAL MAILBOX DATA"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Add Mailboxes  - Up to 9
$addmbx = Read-Host "How many mailboxes does this user need access to (0-9)?"
if ($addmbx -eq 1){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2,$mbx3,$mbx4,$mbx5,$mbx6,$mbx7,$mbx8,$mbx9 = $null
}
elseif ($addmbx -eq 2){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3,$mbx4,$mbx5,$mbx6,$mbx7,$mbx8,$mbx9 = $null
}
elseif ($addmbx -eq 3){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx3 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3 = $mbx3 + $Domain
$mbx4,$mbx5,$mbx6,$mbx7,$mbx8,$mbx9 = $null
}
elseif ($addmbx -eq 4){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx3 = Read-Host "Username? I'll make it an email address"
$mbx4 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3 = $mbx3 + $Domain
$mbx4 = $mbx4 + $Domain
$mbx5,$mbx6,$mbx7,$mbx8,$mbx9 = $null
}
elseif ($addmbx -eq 5){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx3 = Read-Host "Username? I'll make it an email address"
$mbx4 = Read-Host "Username? I'll make it an email address"
$mbx5 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3 = $mbx3 + $Domain
$mbx4 = $mbx4 + $Domain
$mbx5 = $mbx5 + $Domain
$mbx6,$mbx7,$mbx8,$mbx9 = $null
}
elseif ($addmbx -eq 6){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx3 = Read-Host "Username? I'll make it an email address"
$mbx4 = Read-Host "Username? I'll make it an email address"
$mbx5 = Read-Host "Username? I'll make it an email address"
$mbx6 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3 = $mbx3 + $Domain
$mbx4 = $mbx4 + $Domain
$mbx5 = $mbx5 + $Domain
$mbx6 = $mbx6 + $Domain
$mbx7,$mbx8,$mbx9 = $null
}
elseif ($addmbx -eq 7){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx3 = Read-Host "Username? I'll make it an email address"
$mbx4 = Read-Host "Username? I'll make it an email address"
$mbx5 = Read-Host "Username? I'll make it an email address"
$mbx6 = Read-Host "Username? I'll make it an email address"
$mbx7 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3 = $mbx3 + $Domain
$mbx4 = $mbx4 + $Domain
$mbx5 = $mbx5 + $Domain
$mbx6 = $mbx6 + $Domain
$mbx7 = $mbx7 + $Domain
$mbx8,$mbx9 = $null
}
elseif ($addmbx -eq 8){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx3 = Read-Host "Username? I'll make it an email address"
$mbx4 = Read-Host "Username? I'll make it an email address"
$mbx5 = Read-Host "Username? I'll make it an email address"
$mbx6 = Read-Host "Username? I'll make it an email address"
$mbx7 = Read-Host "Username? I'll make it an email address"
$mbx8 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3 = $mbx3 + $Domain
$mbx4 = $mbx4 + $Domain
$mbx5 = $mbx5 + $Domain
$mbx6 = $mbx6 + $Domain
$mbx7 = $mbx7 + $Domain
$mbx8 = $mbx8 + $Domain
$mbx9 = $null
}
elseif ($addmbx -eq 9){
$mbx1 = Read-Host "Username? I'll make it an email address"
$mbx2 = Read-Host "Username? I'll make it an email address"
$mbx3 = Read-Host "Username? I'll make it an email address"
$mbx4 = Read-Host "Username? I'll make it an email address"
$mbx5 = Read-Host "Username? I'll make it an email address"
$mbx6 = Read-Host "Username? I'll make it an email address"
$mbx7 = Read-Host "Username? I'll make it an email address"
$mbx8 = Read-Host "Username? I'll make it an email address"
$mbx9 = Read-Host "Username? I'll make it an email address"
$mbx1 = $mbx1 + $Domain
$mbx2 = $mbx2 + $Domain
$mbx3 = $mbx3 + $Domain
$mbx4 = $mbx4 + $Domain
$mbx5 = $mbx5 + $Domain
$mbx6 = $mbx6 + $Domain
$mbx7 = $mbx7 + $Domain
$mbx8 = $mbx8 + $Domain
$mbx9 = $mbx9 + $Domain
}
else{
$mbx1,$mbx2,$mbx3,$mbx4,$mbx5,$mbx6,$mbx7,$mbx8,$mbx9 = $null
}

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 2D - COLLECTING TEAMS DATA"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Showing all Private Channels in Team
Get-TeamChannel -GroupId $TeamsGroupId -MembershipType Private | ft DisplayName,MembershipType 

#Get private channels to add - Up to 9
$ctoa = Read-Host "How many private channels to add? (0-9)"
if ($ctoa -eq 1){
$channel1 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 2){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 3){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
$channel3 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 4){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
$channel3 = Read-Host "Channel Name?"
$channel4 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 5){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
$channel3 = Read-Host "Channel Name?"
$channel4 = Read-Host "Channel Name?"
$channel5 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 6){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
$channel3 = Read-Host "Channel Name?"
$channel4 = Read-Host "Channel Name?"
$channel5 = Read-Host "Channel Name?"
$channel6 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 7){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
$channel3 = Read-Host "Channel Name?"
$channel4 = Read-Host "Channel Name?"
$channel5 = Read-Host "Channel Name?"
$channel7 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 8){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
$channel3 = Read-Host "Channel Name?"
$channel4 = Read-Host "Channel Name?"
$channel5 = Read-Host "Channel Name?"
$channel7 = Read-Host "Channel Name?"
$channel8 = Read-Host "Channel Name?"
}
elseif ($ctoa -eq 9){
$channel1 = Read-Host "Channel Name?"
$channel2 = Read-Host "Channel Name?"
$channel3 = Read-Host "Channel Name?"
$channel4 = Read-Host "Channel Name?"
$channel5 = Read-Host "Channel Name?"
$channel7 = Read-Host "Channel Name?"
$channel8 = Read-Host "Channel Name?"
$channel9 = Read-Host "Channel Name?"
}
else{
$channel1,$channel2,$channel3,$channel4,$channel5,$channel6,$channel7,$channel8,$channel9 = $null
}

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 2 - COLLECTING DATA - COMPLETED"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 3 - AD USER SETUP - STARTING"
get-date -Format "MM/dd/yyyy HH:mm:ss"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Manager Setup
$Manager = Get-ADUser -Filter "Mail -like '$ManagerInput + $Domain'"

# Process that creates email address
$Mail = $SAMAccountLower.ToLower() + $Domain

# Process that creates other field data that needs to filled in for Exchange Online & Signatures
$ProxyAddress1 = "SMTP:" + $Mail
$UserPrincipalName = $Mail
$Description = $Department + " - " + $title

# Setting OU that Account will Reside in
# Suggest using search filter in pop-up "ou=user" to return user ou's
$SelectOU = Get-ADOrganizationalUnit -Filter * -SearchBase $SearchBase

#Adding the User into AD
$splat = @{
Path = $SelectOU
SamAccountName = $SamAccountLower
GivenName = $GivenName
Surname = $Surname
Name = $DisplayName
DisplayName = $DisplayName
EmailAddress = $Mail
UserPrincipalName = $Mail
Title = $title
Description = $Description
Enabled = $true
ChangePasswordAtLogon = $false
PasswordNeverExpires  = $true
AccountPassword = $defpassword
EmployeeID = $EmpID
OfficePhone = $Phone
Office = $Office
Department = $Department
Manager = $Manager
StreetAddress = $StreetAddress
City = $City
State = $State
PostalCode = $PostCode 
Company = $Company
CannotChangePassword = $true
OtherAttributes = @{proxyAddresses = ($ProxyAddress1)}
}

New-ADUser @splat -Verbose
Set-ADUser $SAMAccountLower
Set-ADUser $SAMAccountLower -add @{Co = $Country}

#Adding the User to the Security Group
Add-ADGroupMember -Identity $SecurityGroup1 -Members $SAMAccountLower

#Try Loop to check for sync to 0365 Portal. Waits and checks every 5 minutes.
Try {
        Do {            
            Start-Sleep -Seconds 300
            Write-Host "Checking for account in MS Online at " 
            get-date -Format "MM/dd/yyyy HH:mm:ss"
            $checkaccountsync = Get-MsolUser -UserPrincipalName $Mail
        } While ($checkaccountsync -eq $null)
        
    } catch {}

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "USER HAS BEEN FOUND IN MSOL!" 
get-date -Format "MM/dd/yyyy HH:mm:ss"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 3 - AD USER SETUP - COMPLETED"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 4 - EMAIL ACCOUNT CREATION - STARTING"
Write-Host "*******************************************************************"
Write-Host  "`n"

#License user's mailbox 
Set-MsolUser  -UserPrincipalName $Mail -UsageLocation US 
#Main Office License
Set-MsolUserLicense  -UserPrincipalName $Mail -AddLicenses $License1
#Any Other
Set-MsolUserLicense  -UserPrincipalName $Mail -AddLicenses $License2

#Try Loop to check for mailbox creation after licenses set. Waits and checks every 10 minutes.
Try {
        Do {            
            Start-Sleep -Seconds 600
            Write-Host "Looking for license sync at " 
            get-date -Format "MM/dd/yyyy HH:mm:ss"
            $checklicensesync = Get-Mailbox -Identity $Mail
        } While ($checklicensesync -eq $null)
        
    } catch {}

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "MAILBOX HAS BEEN FOUND!" 
get-date -Format "MM/dd/yyyy HH:mm:ss"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 4 - EMAIL ACCOUNT CREATION - COMPLETED"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 5 - COPYING OUTLOOK SIGNATURE - STARTING"
Write-Host "*******************************************************************"
Write-Host  "`n"

$Signature = Get-MailboxMessageConfiguration $BorrowUserSignature

Set-MailboxMessageConfiguration $Mail -SignatureHtml $Signature.SignatureHtml 
Set-MailboxMessageConfiguration $Mail -AutoAddSignature $true -AlwaysShowBcc $true -DefaultFontName $DefaultFontName -DefaultFontSize $DefaultFontSize -AlwaysShowFrom $true

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 5 - COPYING OUTLOOK SIGNATURE - COMPLETED"
Write-Host "*******************************************************************"
Write-Host  "`n"


Write-Host "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 6 - ADDING USER TO DLS - STARTING"
Write-Host "*******************************************************************"
Write-Host "`n"

#Add to DL
Add-DistributionGroupMember -Identity $standarddl1 -Member "$Mail"

#Add to Delievery Management
Set-DistributionGroup $standarddl1 –AcceptMessagesOnlyFrom @{add="$Mail"}

#Add to DL
Add-DistributionGroupMember -Identity $standarddl2 -Member "$Mail"

#Add to Delievery Management
Set-DistributionGroup $standarddl2 –AcceptMessagesOnlyFrom @{add="$Mail"}

if($adddls -eq 1){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
}
elseif ($adddls -eq 2){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
}
elseif ($adddls -eq 3){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
Add-DistributionGroupMember -Identity $dl3 -Member $Mail
}
elseif ($adddls -eq 4){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
Add-DistributionGroupMember -Identity $dl3 -Member $Mail
Add-DistributionGroupMember -Identity $dl4 -Member $Mail
}
elseif ($adddls -eq 5){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
Add-DistributionGroupMember -Identity $dl3 -Member $Mail
Add-DistributionGroupMember -Identity $dl4 -Member $Mail
Add-DistributionGroupMember -Identity $dl5 -Member $Mail
}
elseif ($adddls -eq 6){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
Add-DistributionGroupMember -Identity $dl3 -Member $Mail
Add-DistributionGroupMember -Identity $dl4 -Member $Mail
Add-DistributionGroupMember -Identity $dl5 -Member $Mail
Add-DistributionGroupMember -Identity $dl6 -Member $Mail
}
elseif ($adddls -eq 7){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
Add-DistributionGroupMember -Identity $dl3 -Member $Mail
Add-DistributionGroupMember -Identity $dl4 -Member $Mail
Add-DistributionGroupMember -Identity $dl5 -Member $Mail
Add-DistributionGroupMember -Identity $dl6 -Member $Mail
Add-DistributionGroupMember -Identity $dl7 -Member $Mail
}
elseif ($adddls -eq 8){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
Add-DistributionGroupMember -Identity $dl3 -Member $Mail
Add-DistributionGroupMember -Identity $dl4 -Member $Mail
Add-DistributionGroupMember -Identity $dl5 -Member $Mail
Add-DistributionGroupMember -Identity $dl6 -Member $Mail
Add-DistributionGroupMember -Identity $dl7 -Member $Mail
Add-DistributionGroupMember -Identity $dl8 -Member $Mail
}
elseif ($adddls -eq 9){
Add-DistributionGroupMember -Identity $dl1 -Member $Mail
Add-DistributionGroupMember -Identity $dl2 -Member $Mail
Add-DistributionGroupMember -Identity $dl3 -Member $Mail
Add-DistributionGroupMember -Identity $dl4 -Member $Mail
Add-DistributionGroupMember -Identity $dl5 -Member $Mail
Add-DistributionGroupMember -Identity $dl6 -Member $Mail
Add-DistributionGroupMember -Identity $dl7 -Member $Mail
Add-DistributionGroupMember -Identity $dl8 -Member $Mail
Add-DistributionGroupMember -Identity $dl9 -Member $Mail
}
else {
}

Write-Host "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 6 - ADDING USER TO DLS - COMPLETED"
Write-Host "*******************************************************************"
Write-Host "`n"

Write-Host "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 7 - ADD MAILBOXES - STARTING"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Set Mailbox Permissions
if($addmbx -eq 1){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 2){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 3){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx3 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 4){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx3 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx4 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 5){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx3 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx4 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx5 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 6){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx3 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx4 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx5 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx6 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 7){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx3 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx4 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx5 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx6 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx7 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 8){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx3 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx4 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx5 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx6 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx7 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx8 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
elseif($addmbx -eq 9){
Add-MailboxPermission -Identity $mbx1 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx2 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx3 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx4 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx5 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx6 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx7 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx8 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
Add-MailboxPermission -Identity $mbx9 -User $Mail -AccessRight FullAccess -InheritanceType All -Automapping $true
}
else {
}

Write-Host "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 7 - ADD MAILBOXES - COMPLETED"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 8 - ADD USER TO INTRANET ACCESS - STARTING"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Adding User to Sharepoint
Add-SPOUser -Group $intranetgroup -LoginName $Mail -Site $IntranetSiteURL 

Write-Host "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 8 - ADD USER TO INTRANET ACCESS - COMPLETED"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 9 - TEAMS PERMISSIONS ADD - STARTING"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Adding to all public channels
Add-TeamUser -GroupId $TeamsGroupId -User $Mail

#Sleep to ensure user is added to Team
Start-Sleep -Seconds 60

#Adds based on amount of channels to add
if ($ctoa -eq 1)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
}
if ($ctoa -eq 2)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
}
if ($ctoa -eq 3)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel3 -User $Mail
}
if ($ctoa -eq 4)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel3 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel4 -User $Mail
}
if ($ctoa -eq 5)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel3 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel4 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel5 -User $Mail
}
if ($ctoa -eq 6)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel3 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel4 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel5 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel6 -User $Mail
}
if ($ctoa -eq 7)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel3 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel4 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel5 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel6 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel7 -User $Mail
}
if ($ctoa -eq 8)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel3 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel4 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel5 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel6 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel7 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel8 -User $Mail
}
if ($ctoa -eq 9)
{
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel1 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel2 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel3 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel4 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel5 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel6 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel7 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel8 -User $Mail
Add-TeamChannelUser -GroupId $TeamsGroupId -DisplayName $channel9 -User $Mail
}
else
{
}

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 9 - TEAMS PERMISSIONS ADD - COMPLETED"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 10 - CLOSING CONNECTIONS"
Write-Host "*******************************************************************"
Write-Host  "`n"

#Disconnect Exchange
Disconnect-ExchangeOnline

#Disconnect Intranet
Disconnect-SPOService

#Disconnect Teams
Disconnect-MicrosoftTeams 

Write-Host  "`n"
Write-Host "*******************************************************************"
Write-Host "SECTION 11 - PRINTING NEW USER INFORMATION"
get-date -Format "MM/dd/yyyy HH:mm:ss"
Write-Host "*******************************************************************"
Write-Host  "`n"

Write-Host "
Full Name:               $GivenName $Surname
Username:                $SAMAccountLower
Email Address is:        $Mail
Department/Title:        $Description
Office Location:         $Office
Phone:                   $Phone    
Manager is:              $Manager
OU is:                   $SelectOU
DLs Added:               $dl1, $dl2, $dl3, $dl4, $dl5, $dl6, $dl7, $dl8, $dl9
Mailboxes Added:         $mbx1, $mbx2, $mbx3, $mbx4, $mbx5, $mbx6, $mbx7, $mbx8, $mbx9
Intranet Add:            $IntranetSiteURL
Teams Channels:          $channel1, $channel2, $channel3, $channel4, $channel5, $channel6, $channel7, $channel8, $channel9"
