# createuser_powershell
Create User within Microsoft Office 365

ACCOUNT CREATION AUTOMATION

Meant to completely automate account setup and onboarding for institution. 
Involves AD, MS Licenses, Email, Signature, DLs, Additional Mailbox Permissions, Intranet, & Teams.

This powershell script works specifically for a physical AD Server with replication to Office 365. 
Differing setup may require changes to the powershell.

By David Zearbaugh - 3/22/2022

Original scipt by Josh McMullin - 
https://community.spiceworks.com/topic/2249950-powershell-automate-user-and-mailbox-creation

*************************************************************************************
IMPORTANT! UPDATE STEPS A, B, & C PRIOR TO ATTEMPTING RUN
*************************************************************************************

A. PREREQUISITES - WHAT YOU NEED PRIOR TO RUNNING
B. VARIIABLE SETUP - ENTER INSTITUTIONAL DATA
C. SECTIONS TO UPDATE - YOU NEED TO UPDATE THESE BEFORE RUNNING


USER CREATION POWERSHELL DOES THE FOLLOWING:

SECTION 1 -  Conenction to Modules
SECTION 2 -  Collects Necessary Data
SECTION 2A - Collects AD Data
SECTION 2B - Collects Distribution List Data
SECTION 2C - Collects Additional Mailbox Data
SECTION 2D - Collects Teams Data
SECTION 3 -  Creates User in AD
SECTION 4 -  Adds Licensing to Account
SECTION 5 -  Copies Signature over from Standard User
SECTION 6 -  Adds User to Necessary Distribution Lists
SECTION 7 -  Gives Option to Add Mailbox Access (View Mailboxes Only)
SECTION 8 -  Adds User to Intranet
SECTION 9 -  Adds User to Teams
SECTION 10 - Disconnecting from Modules
SECTION 11 - Printing New User Information


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


*************************************************************************************
B. VARIABLE SETUP - ENTER INSTITUTIONAL DATA HERE PRIOR TO RUNNING
*************************************************************************************

DO VARIABLE SETUP IN POWERSHELL FILE

*************************************************************************************
C. SECTIONS TO UPDATE
*************************************************************************************

1. $setaddress in SECTION 2A - Add/Remove/Update Address Information Settings
2. $setDepartment in SECTION 2A - Add/Remove/Update Department Information Settings
