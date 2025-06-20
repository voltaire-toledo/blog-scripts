<#
.SYNOPSIS
Seals the current system to prepare for snapshot and deployment. Must be run in an administrative context.

.DESCRIPTION
The Seal-Image.ps1 script performs various sealing tasks and saves details to the following files:
- .\Seal-Image-Transcript_(date_time).log
- .\Seal-Image_Manifest.log

.PARAMETER SkipManifest
Skips the prompts for the administrator to enter a list of changes to record in the manifest.

.PARAMETER PromptAll
Forces prompts for all, except when the -SkipManifest parameter is used (administrator is not prompted for entering info into the manifest)

.INPUTS
Download DELPROF2.EXE from: https://helgeklein.com/free-tools/delprof2-user-profile-deletion-tool/
Download Reset-TSGracePeriod.ps1 from: https://github.com/adamgell/Scripts/blob/master/Reset-TSGracePeriod.ps1

.OUTPUTS
FILE: Seal-Image-Transcript-(date_time).log
  Contains the host output of each sealing task. A separate log file is created every time the script is launched.

FILE: Seal-Image-Manifest.log
  Contains the log of changes reported by the administrator performing the sealing activities.

.NOTES
CHANGE LOG:
1.0 :
    - Initial Release

1.1 :
    - Added -PromptAll switch parameter support
    - Added Action: Disable the Adobe Acrobat Update Service (AdobeARMservice)
    - Added Action: Disable the Google Update Service (gupdate)
    - Added Action: Disable the Google Update Service (gupdatem)

.EXAMPLE
PS> .\Seal-Image.ps1
 
#>
 
#Requires -RunAsAdministrator
param (
    [switch]$SkipManifest = $false,
    [switch]$PromptAll = $false
)

function Get-TimeStamp {Get-Date -Format yyyy-MM-dd_hh-mm-ss}
 
function Start-ManifestEntry{
  Write-Host "`n******$CurrentAction*****"
  (Get-TimeStamp) + ": $CurrentAction (Start)" | Tee-Object $ManifestLogFile -Append
  if ($PromptAll -eq $true) {
    Write-Host "Do you wish to continue with *$CurrentAction* (" -ForegroundColor Green -NoNewline
    Write-Host "y/n" -ForegroundColor Yellow -NoNewline
    Write-Host ")?" -ForegroundColor Green -NoNewline
    $Continue = Read-Host
    if ($Continue -eq "n") {
        Write-Host "Skipping $CurrentAction." | Tee-Object $ManifestLogFile -Append
        $ContinueAction = $false
    }}
  $script:ActionStart = Get-Date
}
 
function End-ManifestEntry{
  $ActionEnd = Get-Date
  $ActionDuration = [math]::Round(($ActionEnd.Subtract($script:ActionStart)).TotalSeconds, 2)
  (Get-TimeStamp) + ": $CurrentAction (End: $ActionDuration sec.)" | Tee-Object $ManifestLogFile -Append
  $ContinueAction = $true
}
 
$script:TranscriptLogFile = $PSScriptRoot + "\Seal-Image-Transcript_" + (Get-TimeStamp) + ".log"
$script:ManifestLogFile = $PSScriptRoot + "\Seal-Image-Manifest.log"
$script:ContinueAction = $true
$script:SealStart = Get-Date
 
Clear-Host
Start-Transcript -Path $TranscriptLogFile |Out-Null
 
"================================ Begin Seal-Image ===============================" | Out-File $ManifestLogFile -Append
 
#############################################################
## Collecting a manifest of changes from the administrator
if ($SkipManifest -eq $true) {
    (Get-TimeStamp) + ": Skipping Manifest collection because of the -SkipManifest parameter." | Tee-Object $ManifestLogFile -Append
}
else {
    $CurrentAction = "Collecting a manifest of changes from the administrator"
    Start-ManifestEntry
 
    # Collect input until '[quit]' is entered in a single line
    $AdminInput = @()
    $InputLine = ''
    Write-Host "Describe an image change in each line. Enter" -ForegroundColor Green -NoNewline
    Write-Host " [quit] " -ForegroundColor Yellow -NoNewline
    Write-Host "in a new line to exit: " -ForegroundColor Green
 
    While($InputLine -ne "[quit]"){
      If ($InputLine -ne $null){
        $AdminInput += "CHANGE: " + $InputLine.Trim()
      }
      $InputLine = Read-Host
    }
    $AdminInput = $AdminInput[1..($AdminInput.Length-1)]
    $AdminInput | Tee-Object $ManifestLogFile -Append
    End-ManifestEntry
}
 
###################################
## Displaying installed Hotfixes 
$CurrentAction = "Displaying the Installed Microsoft Hotfixes"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    Get-Hotfix | Sort-Object -Property InstalledOn
}
End-ManifestEntry
 
##################################################
## Updating the Micorosft PowerShell help files 
$CurrentAction = "Updating the Microsoft PowerShell help files"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    Update-Help -Force -ErrorAction SilentlyContinue
}
End-ManifestEntry
 
#############################
## Clearing All Event Logs 
$CurrentAction = "Clearing All Event Logs"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    & wevtutil.exe el |   ForEach-Object {
    Write-Host -ForegroundColor Gray "Clearing $_"   
    wevtutil.exe cl "$_" 2>$null
    } -ErrorAction SilentlyContinue
}
End-ManifestEntry
 
########################################
## Clearing IE Cookies, History, etc. 
$CurrentAction = "Clearing IE Cookies, History, etc."
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    & RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 4351 | Wait-Process
}
End-ManifestEntry
 
################################################
## Emptying the downloaded MS Updates Folder
$CurrentAction = "Emptying the downloaded MS Updates Folder"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    Remove-Item -Path C:\Windows\SoftwareDistribution\Download\* -Filter * -Recurse
}
End-ManifestEntry
 
#####################################
## Removing Phantom Drive Mappings
$CurrentAction = "Removing Phantom Drive Mappings"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_Users -ErrorAction SilentlyContinue
    Remove-Item -Path HKU:\.DEFAULT\Network\* -Filter * -Recurse -ErrorAction SilentlyContinue
    Remove-PSDrive HKU -ErrorAction SilentlyContinue
}
End-ManifestEntry
 
###########################
## Clearing Temp Folders 
$CurrentAction = "Clearing Temp Folders"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    Remove-Item -Path C:\Windows\Temp\* -Filter * -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path C:\Temp\* -Filter * -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path $env:APPDATA\Microsoft\Windows\Recent\* -Recurse -ErrorAction SilentlyContinue
}
End-ManifestEntry
 
########################################
## Deleting Unnecessary User Profiles 
$CurrentAction = "Deleting Unnecessary User Profiles"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    $CommandToRun = (Split-Path -Path $PSCommandPath -Parent) + "\DELPROF2.EXE"
    $CommandArgs = "/Q"  # '/L' for DEBUG, '/Q' for PROD
    & $CommandToRun $CommandArgs
}
End-ManifestEntry
 
###########################
## Applying Group Policy 
$CurrentAction = "Applying Group Policy"
if ($script:ContinueAction -eq $true) {
    Write-Host "Please wait..."
    Start-ManifestEntry
    Start-Process GPUPDATE.EXE -ArgumentList '/Force' -Wait
}
End-ManifestEntry
 
################################
## Uninstalling the GFI Agent 
$CurrentAction = "Uninstalling the GFI Agent"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    & MsiExec.exe /X {160301DE-306A-4ADE-8A47-BC5790AF0486} /PASSIVE /NORESTART
}
End-ManifestEntry
 
#################################
## Disabling Hybernate Feature 
$CurrentAction = "Disabling Hybernate Feature"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    & POWERCFG.EXE /HIBERNATE OFF
}
End-ManifestEntry
 
###################################
## Resetting the TS Grace Period 
# Only run in a Server operating system
$WinClass = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Host -ForegroundColor Gray "System" ($WinClass).Name
if (($WinClass).ProductType -eq 3){
    # Server OS (non-Domain Controller). Reset the Grace Period.
    $CurrentAction = "Resetting the TS Grace Period"
    Start-ManifestEntry
    if ($script:ContinueAction -eq $true) {
        & "$PSScriptRoot\Reset-TSGracePeriod.ps1"
    }
    End-ManifestEntry
}
 
##########################################
## Disabling the Windows Update Service 
$CurrentAction = "Disabling the Windows Update Service"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    Stop-Service -Name wuauserv
    Set-Service -Name wuauserv -StartupType Disabled
}
End-ManifestEntry
 
##########################################
## Disabling the Google Update Services 
$CurrentAction = "Disabling the Google Update Services"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    Stop-Service -Name gupdate
    Set-Service -Name gupdate -StartupType Disabled
 
    Stop-Service -Name gupdatem
    Set-Service -Name gupdatem -StartupType Disabled
}
End-ManifestEntry
 
################################################
## Disabling the Adobe Acrobat Update Service 
$CurrentAction = "Disabling the Adobe Acrobat Update Service"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
   Stop-Service -Name AdobeARMservice
    Set-Service -Name AdobeARMservice -StartupType Disabled
}
End-ManifestEntry
 
######################################
## Clearing out the Citrix UPM logs
$CurrentAction = "Clearing out the Citrix UPM logs"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    Stop-Service -Name ctxProfile
    Remove-Item -Path C:\Windows\System32\LogFiles\UserProfileManager\* -Filter * -Recurse
    # Skip restarting the service until next reboot.
}
End-ManifestEntry
 
########################
## Flushing DNS Cache
$CurrentAction = "Flushing DNS Cache"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    & IPCONFIG /flushdns #/renew
}
End-ManifestEntry
 
#############################################
## Releasing the IP lease back in the pool 
$CurrentAction = "Releasing the IP lease"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    & IPCONFIG /release
}
End-ManifestEntry
 
<#
##############
## TEMPLATE 
$CurrentAction = "Templating the Stuffing"
Start-ManifestEntry
if ($script:ContinueAction -eq $true) {
    ## MEAT ##
}
End-ManifestEntry
#>
 
Write-Host -ForegroundColor Yellow "NOTE: If the paravirtual drivers (VMWare Tools) was updated, please review the network adapter settings."
Write-Host -ForegroundColor Green "Congratulations! Seal-Image has completed its activities."
Write-Host -ForegroundColor Green "Please hit the [Enter] key to continue." -NoNewline
Read-Host | Out-Null
$SealEnd = Get-Date
$SealDuration = [math]::Round(($SealEnd.Subtract($SealStart)).TotalSeconds, 2)
"================================= End Seal-Image ================================= (Total: $SealDuration sec.)" | Out-File $ManifestLogFile -Append
Stop-Transcript | Out-Null
# shutdown -s -t 300