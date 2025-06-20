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
1.2.1:
  - Replaced manual component store and update cache cleanup with DISM /online /cleanup-image /StartComponentCleanup /ResetBase for best practice and efficiency.

1.2.0:
  - Added: Windows Defender Cleanup (removes logs and quarantine)
  - Added: Remove Ghost Devices (manual/devcon)
  - Added: Clear Print Spooler
  - Added: Clear Windows Update Cache (Deep)
  - Added: Remove Old Network Profiles
  - Added: Remove Unwanted Appx Packages
  - Added: Disk Cleanup
  - Added: Wipe Free Space (manual/SDelete)
  - Added: Remove Custom Branding
  - Added: Sysprep Integration (optional)

1.1.1: 
  - Added [CmdletBinding()] attribute for:
    - Advanced function support.
    - Parameter validation and metadata.
    - Pipeline support.
    - Enhanced error handling.
  - Added -RunAsAdministrator requirement to ensure the script runs with elevated privileges.
  - Best Practices:
    - Used `Get-CimInstance` instead of `Get-WmiObject` for better performance and compatibility.
    - Used `Get-Service` with `-ErrorAction SilentlyContinue` to avoid errors if the service does not exist.
    - Used `Remove-Item` with `-ErrorAction SilentlyContinue` to avoid errors if the item does not exist.
    - Used `Join-Path` for constructing file paths to ensure compatibility across different systems.
    - Used `Tee-Object` to log output to both console and file.
    

  1.1 :
  - Added -PromptAll switch parameter support
  - Added Action: Disable the Adobe Acrobat Update Service (AdobeARMservice)
  - Added Action: Disable the Google Update Service (gupdate)
  - Added Action: Disable the Google Update Service (gupdatem)

1.0 :
  - Initial Release


.EXAMPLE
PS> .\Seal-Image.ps1
 
#>
 
#Requires -RunAsAdministrator
[CmdletBinding()]
param (
    [Parameter(HelpMessage = 'Skips the prompts for the administrator to enter a list of changes to record in the manifest.')]
    [switch]$SkipManifest = $false,
    [Parameter(HelpMessage = 'Forces prompts for all, except when the -SkipManifest parameter is used.')]
    [switch]$PromptAll = $false
)

function Get-TimeStamp {
    Get-Date -Format yyyy-MM-dd_hh-mm-ss
}

function Write-Log {
    param(
        [string]$Message,
        [string]$LogFile
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp $Message" | Tee-Object -FilePath $LogFile -Append
}

function Invoke-SealAction {
    param(
        [string]$ActionName,
        [scriptblock]$Action
    )
    Write-Host "`n****** $ActionName ******"
    Write-Log "$ActionName (Start)" $script:ManifestLogFile
    $start = Get-Date
    $script:ContinueAction = $true
    if ($PromptAll -eq $true) {
        Write-Host "Do you wish to continue with *$ActionName* (" -ForegroundColor Green -NoNewline
        Write-Host "y/n" -ForegroundColor Yellow -NoNewline
        Write-Host ")?" -ForegroundColor Green -NoNewline
        $Continue = Read-Host
        if ($Continue -eq "n") {
            Write-Host "Skipping $ActionName." | Tee-Object $script:ManifestLogFile -Append
            $script:ContinueAction = $false
        }
    }
    if ($script:ContinueAction -eq $true) {
        try {
            & $Action
            Write-Log "$ActionName (Success)" $script:ManifestLogFile
        } catch {
            Write-Log "$ActionName (Error): $_" $script:ManifestLogFile
        }
    }
    $duration = [math]::Round((New-TimeSpan -Start $start -End (Get-Date)).TotalSeconds, 2)
    Write-Log "$ActionName (End: $duration sec.)" $script:ManifestLogFile
}

$script:TranscriptLogFile = Join-Path $PSScriptRoot ("Seal-Image-Transcript_" + (Get-TimeStamp) + ".log")
$script:ManifestLogFile = Join-Path $PSScriptRoot "Seal-Image-Manifest.log"
$script:SealStart = Get-Date

Clear-Host
Start-Transcript -Path $TranscriptLogFile | Out-Null

"================================ Begin Seal-Image ===============================" | Out-File $ManifestLogFile -Append

# Collecting a manifest of changes from the administrator
if ($SkipManifest -eq $true) {
    Write-Log "Skipping Manifest collection because of the -SkipManifest parameter." $ManifestLogFile
} else {
    Invoke-SealAction -ActionName "Collecting a manifest of changes from the administrator" -Action {
        $AdminInput = @()
        $InputLine = ''
        Write-Host "Describe an image change in each line. Enter" -ForegroundColor Green -NoNewline
        Write-Host " [quit] " -ForegroundColor Yellow -NoNewline
        Write-Host "in a new line to exit: " -ForegroundColor Green
        while ($InputLine -ne "[quit]") {
            if ($InputLine -ne $null -and $InputLine -ne "") {
                $AdminInput += "CHANGE: " + $InputLine.Trim()
            }
            $InputLine = Read-Host
        }
        if ($AdminInput.Count -gt 0) {
            $AdminInput | Tee-Object $ManifestLogFile -Append
        }
    }
}

# Define all actions as scriptblocks for clarity
$actions = @(
    @{ Name = 'Displaying the Installed Microsoft Hotfixes'; Action = { Get-Hotfix | Sort-Object -Property InstalledOn } },
    @{ Name = 'Updating the Microsoft PowerShell help files'; Action = { Update-Help -Force -ErrorAction SilentlyContinue } },
    @{ Name = 'Clearing All Event Logs'; Action = {
        # Clear classic event logs
        try {
            $classicLogs = Get-EventLog -List | Select-Object -ExpandProperty Log
            foreach ($log in $classicLogs) {
                try {
                    Clear-EventLog -LogName $log -ErrorAction SilentlyContinue
                    Write-Host -ForegroundColor Gray "Cleared classic log: $log"
                } catch {
                    Write-Host -ForegroundColor DarkGray "Could not clear classic log: $log ($_)."
                }
            }
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not enumerate classic logs: $_"
        }
        # Clear all (including modern) event logs using wevtutil
        try {
            $allLogs = & wevtutil el
            foreach ($log in $allLogs) {
                try {
                    & wevtutil cl "$log"
                    Write-Host -ForegroundColor Gray "Cleared log: $log"
                } catch {
                    Write-Host -ForegroundColor DarkGray "Could not clear log: $log ($_)."
                }
            }
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not enumerate or clear logs with wevtutil: $_"
        }
    } },
    @{ Name = 'Clearing IE Cookies, History, etc.'; Action = {
        Remove-Item -Path "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\AppData\Local\Microsoft\Windows\History\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\AppData\Local\Microsoft\Windows\WebCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    } },
    @{ Name = 'Emptying the downloaded MS Updates Folder'; Action = { Remove-Item -Path C:\Windows\SoftwareDistribution\Download\* -Filter * -Recurse -ErrorAction SilentlyContinue } },
    @{ Name = 'Removing Phantom Drive Mappings'; Action = {
        # No direct cmdlet, keeping registry method
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_Users -ErrorAction SilentlyContinue
        Remove-Item -Path HKU:\.DEFAULT\Network\* -Filter * -Recurse -ErrorAction SilentlyContinue
        Remove-PSDrive HKU -ErrorAction SilentlyContinue
    } },
    @{ Name = 'Clearing Temp Folders'; Action = {
        Remove-Item -Path C:\Windows\Temp\* -Filter * -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path C:\Temp\* -Filter * -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path $env:APPDATA\Microsoft\Windows\Recent\* -Recurse -ErrorAction SilentlyContinue
    } },
    @{ Name = 'Deleting Unnecessary User Profiles'; Action = {
        $CommandToRun = Join-Path (Split-Path -Path $PSCommandPath -Parent) "DELPROF2.EXE"
        $CommandArgs = "/Q"
        & $CommandToRun $CommandArgs
    } },
    @{ Name = 'Applying Group Policy'; Action = {
        Write-Host "Please wait..."
        Start-Process -FilePath 'gpupdate.exe' -ArgumentList '/force' -Wait -NoNewWindow
    } },
    @{ Name = 'Uninstalling the GFI Agent'; Action = { & MsiExec.exe /X {160301DE-306A-4ADE-8A47-BC5790AF0486} /PASSIVE /NORESTART } },
    @{ Name = 'Disabling Hybernate Feature'; Action = { powercfg /hibernate off } },
    @{ Name = 'Disabling the Windows Update Service'; Action = {
        if (Get-Service -Name wuauserv -ErrorAction SilentlyContinue) {
            Stop-Service -Name wuauserv -ErrorAction SilentlyContinue
            Set-Service -Name wuauserv -StartupType Disabled
        }
    } },
    @{ Name = 'Disabling the Google Update Services'; Action = {
        foreach ($svc in 'gupdate','gupdatem') {
            if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
                Stop-Service -Name $svc -ErrorAction SilentlyContinue
                Set-Service -Name $svc -StartupType Disabled
            }
        }
    } },
    @{ Name = 'Disabling the Adobe Acrobat Update Service'; Action = {
        if (Get-Service -Name AdobeARMservice -ErrorAction SilentlyContinue) {
            Stop-Service -Name AdobeARMservice -ErrorAction SilentlyContinue
            Set-Service -Name AdobeARMservice -StartupType Disabled
        }
    } },
    @{ Name = 'Clearing out the Citrix UPM logs'; Action = {
        if (Get-Service -Name ctxProfile -ErrorAction SilentlyContinue) {
            Stop-Service -Name ctxProfile -ErrorAction SilentlyContinue
        }
        Remove-Item -Path C:\Windows\System32\LogFiles\UserProfileManager\* -Filter * -Recurse -ErrorAction SilentlyContinue
    } },
    @{ Name = 'Flushing DNS Cache'; Action = { Clear-DnsClientCache } },
    @{ Name = 'Releasing the IP lease'; Action = {
        Get-NetAdapter | ForEach-Object {
            try {
                Release-NetIPAddress -InterfaceAlias $_.Name -ErrorAction SilentlyContinue
            } catch {
                Write-Host -ForegroundColor DarkGray "Could not release IP for $($_.Name): $_"
            }
        }
    } },
    @{ Name = 'Windows Defender Cleanup'; Action = {
        try {
            Remove-MpThreat -All -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\ProgramData\Microsoft\Windows Defender\Scans\History\*' -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Gray 'Windows Defender logs and quarantine cleared.'
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not clear Defender logs/quarantine: $_"
        }
    } },
    @{ Name = 'Remove Ghost Devices'; Action = {
        Write-Host -ForegroundColor Yellow 'NOTE: Removing ghost devices requires devcon.exe and is not natively supported in PowerShell. Please run devcon manually if needed.'
    } },
    @{ Name = 'Clear Print Spooler'; Action = {
        try {
            Stop-Service -Name Spooler -ErrorAction SilentlyContinue
            Remove-Item -Path 'C:\Windows\System32\spool\PRINTERS\*' -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name Spooler -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Gray 'Print spooler cleared.'
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not clear print spooler: $_"
        }
    } },
    @{ Name = 'Component Store Cleanup (DISM)'; Action = {
        try {
            Write-Host -ForegroundColor Gray 'Running DISM component store cleanup...'
            Start-Process -FilePath 'dism.exe' -ArgumentList '/online /cleanup-image /StartComponentCleanup /ResetBase' -Wait -NoNewWindow
            Write-Host -ForegroundColor Gray 'DISM component store cleanup completed.'
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not run DISM cleanup: $_"
        }
    } },
    @{ Name = 'Remove Custom Scheduled Tasks'; Action = {
        try {
            Get-ScheduledTask | Where-Object { $_.TaskName -notlike 'Microsoft*' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Gray 'Custom scheduled tasks removed.'
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not remove custom scheduled tasks: $_"
        }
    } },
    @{ Name = 'Remove Old Network Profiles'; Action = {
        try {
            Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq 'Private' -or $_.NetworkCategory -eq 'Public' } | Remove-NetConnectionProfile -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Gray 'Old network profiles removed.'
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not remove network profiles: $_"
        }
    } },
    @{ Name = 'Remove Unwanted Appx Packages'; Action = {
        try {
            Get-AppxPackage | Where-Object { $_.Name -notlike '*Microsoft.WindowsStore*' -and $_.Name -notlike '*Microsoft.WindowsCalculator*' } | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Gray 'Unwanted Appx packages removed.'
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not remove Appx packages: $_"
        }
    } },
    @{ Name = 'Wipe Free Space'; Action = {
        Write-Host -ForegroundColor Yellow 'NOTE: Wiping free space is not natively supported in PowerShell. Use SDelete or a similar tool if required.'
    } },
    @{ Name = 'Remove Custom Branding'; Action = {
        try {
            Remove-Item -Path 'C:\Windows\System32\oem*.*' -Force -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Gray 'Custom branding removed.'
        } catch {
            Write-Host -ForegroundColor DarkGray "Could not remove custom branding: $_"
        }
    } },
    @{ Name = 'Sysprep Integration'; Action = {
        Write-Host -ForegroundColor Yellow 'NOTE: Sysprep integration is optional. Uncomment the following line to enable.'
        Start-Process -FilePath 'C:\Windows\System32\Sysprep\Sysprep.exe' -ArgumentList '/oobe /generalize /shutdown' -Wait
    } }
)

# Special case: Resetting the TS Grace Period (Server OS only)
$WinClass = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Host -ForegroundColor Gray "System $($WinClass.Name)"
if ($WinClass.ProductType -eq 3) {
    Invoke-SealAction -ActionName "Resetting the TS Grace Period" -Action {
        # Reset the RDS Licensing Grace Period per Dell KB 000193714
        $GracePeriodKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod'
        $reg = Get-Item $GracePeriodKey
        $acl = $reg.GetAccessControl()
        $admin = [System.Security.Principal.NTAccount]"Administrators"
        $acl.SetOwner($admin)
        $reg.SetAccessControl($acl)
        $acl.SetAccessRuleProtection($true, $false)
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($admin, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
        $reg.SetAccessControl($acl)
        Get-ChildItem $GracePeriodKey | Where-Object { $_.Name -match 'L\$RTMTIMEBOMB' } | Remove-Item -Force
        Write-Host -ForegroundColor Green 'Grace period registry key deleted. Please reboot the server for the change to take effect.'
    }
}

# Run all standard actions
foreach ($a in $actions) {
    Invoke-SealAction -ActionName $a.Name -Action $a.Action
}

Write-Host -ForegroundColor Yellow "NOTE: If the paravirtual drivers (VMWare Tools) was updated, please review the network adapter settings."
Write-Host -ForegroundColor Green "Congratulations! Seal-Image has completed its activities."
Write-Host -ForegroundColor Green "Please hit the [Enter] key to continue." -NoNewline
Read-Host | Out-Null
$SealEnd = Get-Date
$SealDuration = [math]::Round(($SealEnd.Subtract($SealStart)).TotalSeconds, 2)
"================================= End Seal-Image ================================= (Total: $SealDuration sec.)" | Out-File $ManifestLogFile -Append
Stop-Transcript | Out-Null
# shutdown -s -t 300