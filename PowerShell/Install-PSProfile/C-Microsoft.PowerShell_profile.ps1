# ╭─────────────────────────────────────╮
# │ PowerShell 7.x Profile - Windows    │
# ╰─────────────────────────────────────╯

$profileLoadStart = Get-Date

#region Globals...
# Set the debug mode.  Use $DebugPreference for more control.
$DebugPreference = 'SilentlyContinue' # Or: 'Continue', 'Stop', 'Inquire'
$Global:CanConnectToGitHub = $false # Initialize, will be set in MAIN
# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
#endregion

# ╭──────────────────╮
# │ Helper Functions │
# ╰──────────────────╯
#region Helper Functions...
function Write-RBox {
  <#
    .SYNOPSIS
        Displays a multi-line string within a decorated box.
    .DESCRIPTION
        Takes a string, splits it into lines, and displays it within a box constructed of ASCII characters. Handles ANSI escape codes for colored output and adjusts the box size to fit the longest line.
    .PARAMETER Text
        The string to display within the box. Newlines (`n) are interpreted as line breaks.
    .PARAMETER BorderColor
        The color of the box border. Default is Cyan. Use $PSStyle.Foreground.<ColorName> to set the color.
    .EXAMPLE
        Write-RBox -Text "This is a test`nwith multiple lines."
  #>
  param (
    [string]$Text,
    [string]$BorderColor = $PSStyle.Foreground.Cyan
  )

  # Decoration variables
  $RstC = $PSStyle.Reset

  # Handle the multiple lines split
  $Lines = $Text -split "`r?`n|`r"

  # Calculate the maximum length of the lines to adjust the box size
  $MaxLength = 0
  foreach ($Line in $Lines) {
    $PrintableLineLength = ($Line -replace "`e\[[\d;]*m", '').Length
    if ($PrintableLineLength -gt $MaxLength) {
      $MaxLength = $PrintableLineLength
    }
  }
    
  # Calculate the number of spaces needed for the box
  $Spaces = ($MaxLength + 2)

  # Print the top border
  Write-Host "$($BorderColor)╭$("─" * $($Spaces))╮$($RstC)"

  # Print the lines inside the box
  foreach ($Line in $Lines) {
    if ($Line.Contains("#divider#")) {
      Write-Host "$($BorderColor)├$("$($BorderColor)─" * $($Spaces))$($BorderColor)┤$($RstC)"
    }
    else {
      $LBorder = "$($BorderColor)│$($RstC) "
      $RBorder = " $($BorderColor)│$($RstC)"
      $PrintableLine = $Line -replace "`e\[[\d;]*m", ''       
      $PadSpaces = $(" " * $($MaxLength - $PrintableLine.Length))
      Write-Host "$($LBorder)$($Line)$($PadSpaces)$($RBorder)"
    }
  }
  # Print the bottom border
  Write-Host "$($BorderColor)╰$("─" * $($Spaces))╯$($RstC)"
}

function Show-Features {
  <#
    .SYNOPSIS
        Displays help information for the PowerShell profile.
    .DESCRIPTION
        Shows a formatted help message, including available aliases, functions, and their descriptions. Uses Write-RBox to present the information in a user-friendly box.
    .EXAMPLE
        Show-Features
  #>
  # Decoration variables
  $SecC = $PSStyle.Foreground.BrightWhite
  $FunC = $PSStyle.Foreground.BrightYellow
  $ParC = $PSStyle.Foreground.Green + $PSStyle.Italic
  $RstC = $PSStyle.Reset

  # Use here-string for better multi-line string handling
  $HelpText = @"
$($SecC)PowerShell Profile Help$($RstC)

$($SecC)   Host:$($RstC) $($Host.Name)
$($SecC)Profile:$($RstC) $PROFILE
#divider#
$($SecC)Features:$($RstC)
  - Winget argument completer
  - Az CLI Argument Completer
  - Choco argument completer
  
$($SecC)Terraform Aliases:
  $($FunC)tf $($RstC)`t       ⁝ $($FunC)terraform         
  $($FunC)tfi$($RstC)`t       ⁝ $($FunC)terraform init -upgrade        
  $($FunC)tfp$($RstC)`t       ⁝ $($FunC)terraform plan        
  $($FunC)tfa$($RstC)`t       ⁝ $($FunC)terraform apply -auto-approve        
  $($FunC)tfd$($RstC)`t       ⁝ $($FunC)terraform destroy -auto-approve
  
$($SecC)Git/GitHub Aliases:
  $($FunC)g$($RstC)               ⁝ Changes to the GitHub directory.
  $($FunC)ga$($RstC)              ⁝ $($FunC)git add .
  $($FunC)gc $($ParC)message$($RstC)      ⁝ $($FunC)git commit -m$($RstC) with the commit's message.
  $($FunC)gcom $($ParC)message$($RstC)    ⁝ $($FunC)git add . && git commit -m$($RstC) with the commit's string.
  $($FunC)gp$($RstC)              ⁝ $($FunC)git push
  $($FunC)gs$($RstC)              ⁝ $($FunC)git status
  $($FunC)yeetg $($ParC)message$($RstC)   ⁝ Just $($FunC)add-commit-push$($RstC) and yeet that shit!
  
$($SecC)Other Functions:
  $($FunC)cpy $($ParC)[text]$($RstC)          ⁝ Copies text to the clipboard.
  $($FunC)df$($RstC)                  ⁝ Displays volume information.
  $($FunC)docs$($RstC)                ⁝ Changes to the Documents folder.
  $($FunC)dtop$($RstC)                ⁝ Changes to the Desktop folder.
  $($FunC)Edit-Profile$($RstC)        ⁝ Opens the CurrentUserCurrentHost PSProfile for editing.
  $($FunC)ep$($RstC)                  ⁝ Opens the CurrentUserAllHosts PSProfile for editing.
  $($FunC)export $($ParC)[env] [var]$($RstC)  ⁝ Sets an environment variable.
  $($FunC)ff $($ParC)[name]$($RstC)           ⁝ Finds files recursively.
  $($FunC)flushdns$($RstC)            ⁝ Clears the DNS cache.
  $($FunC)Get-PubIP$($RstC)           ⁝ Retrieves the public IP.
  $($FunC)grep $($ParC)[regex] [dir]$($RstC)  ⁝ Searches for a regex pattern.
  $($FunC)hb $($ParC)[file]$($RstC)           ⁝ Uploads to hastebin-like service.
  $($FunC)head$ $($ParC)[path] [n]$($RstC)    ⁝ Displays the first n lines.
  $($FunC)k9 $($ParC)[name]$($RstC)           ⁝ Kills a process by name.
  $($FunC)la$($RstC)                  ⁝ Lists files with details.
  $($FunC)ll$($RstC)                  ⁝ Lists all files (including hidden) with details.
  $($FunC)mkcd $($ParC)[dir]$($RstC)          ⁝ Creates and changes to a directory.
  $($FunC)nf $($ParC)[name]$($RstC)           ⁝ Creates a new file.
  $($FunC)o $($ParC)[dir]$($RstC)             ⁝ Open $($FunC)explorer.exe$($RstC) and set $($ParC)[dir]$($RstC) as the CWD
  $($FunC)pgrep $($ParC)[name]$($RstC)        ⁝ Lists processes by name.
  $($FunC)pkill $($ParC)[name]$($RstC)        ⁝ Kills processes by name.
  $($FunC)pst$($RstC)                 ⁝ Retrieves text from the clipboard.
  $($FunC)reload-profile$($RstC)      ⁝ Reloads the PowerShell profile.
  $($FunC)sed $($ParC){1} {2} {3}$($RstC)     ⁝ Replaces text in a file. Values are:
                        $($ParC){1}$($RstC) = $($ParC)File$($RstC) to replace text inside it
                        $($ParC){2}$($RstC) = $($ParC)String to find$($RstC) and replace
                        $($ParC){3}$($RstC) = $($ParC)String to replace$($RstC) what was found
  $($FunC)sysinfo$($RstC)             ⁝ Displays system information.
  $($FunC)tail $($ParC)[file] [n]$($RstC)     ⁝ Displays the last $($ParC)[n]$($RstC) lines of the $($ParC)[file]$($RstC).
  $($FunC)touch $($ParC)[file]$($RstC)        ⁝ Creates a new empty $($ParC)[file]$($RstC).
  $($FunC)unzip$ $($ParC)[file]$($RstC)       ⁝ Extracts a zip file.
  $($FunC)Update-PowerShell$($RstC)   ⁝ Checks for PowerShell updates.
  $($FunC)uptime$($RstC)              ⁝ Displays system uptime.
  $($FunC)which $($ParC)[command]$($RstC)     ⁝ Shows the path of the $($ParC)[command]$($RstC).
"@

  # Print the help text in a box
  Write-RBox -Text $HelpText
}
#endregion

#region PSProfile Management...
# ╭───────────────────────────────────────────────╮
# │ Update-Profile(): Update $PROFILE from GitHub │
# ╰───────────────────────────────────────────────╯
function Update-Profile {
  <#
    .SYNOPSIS
        Updates the PowerShell profile from GitHub.
    .DESCRIPTION
        Downloads the latest profile script from a specified GitHub URL and replaces the current profile if it has changed.
    .EXAMPLE
        Update-Profile
  #>
  try {
    $url = "https://raw.githubusercontent.com/ChrisTitusTech/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
    $oldhash = Get-FileHash $PROFILE
    Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
    $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
    if ($newhash.Hash -ne $oldhash.Hash) {
      Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
      Write-Host "Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
    }
    else {
      Write-Host "Profile is up to date." -ForegroundColor Green
    }
  }
  catch {
    Write-Error "Unable to check for `$profile updates: $_"
  }
  finally {
    Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
  }
}

# Edit-Profile(): Edit the $PROFILE.CurrentUserAllHosts profile
function Edit-Profile {
  <#
    .SYNOPSIS
        Opens the CurrentUserAllHosts profile for editing.
    .DESCRIPTION
        Launches the editor (vim) to edit the $PROFILE.CurrentUserAllHosts file.
    .EXAMPLE
        Edit-Profile
  #>
  vim $PROFILE.CurrentUserAllHosts
}

# Edit-ThisProfile(): Edit the $PROFILE.CurrentUserAllHosts profile
function Edit-ThisProfile {
  <#
    .SYNOPSIS
        Opens the CurrentUserCurrentHost profile for editing.
    .DESCRIPTION
        Launches the editor (vim) to edit the $PROFILE.CurrentUserCurrentHost file.
    .EXAMPLE
        Edit-ThisProfile
  #>
  vim $PROFILE.CurrentUserCurrentHost
}
#endregion

#region Aliases & Functions...
function touch($file) { 
  <#
    .SYNOPSIS
        Creates a new empty file.
    .DESCRIPTION
        Mimics the UNIX 'touch' command by creating a new empty file or updating the timestamp if it exists.
    .PARAMETER file
        The name of the file to create or update.
    .EXAMPLE
        touch 'example.txt'
  #>
  # touch -> Create a new empty file
  "" | Out-File $file -Encoding ASCII 
}

function ff($name) { 
  <#
    .SYNOPSIS
        Finds files recursively by name.
    .DESCRIPTION
        Searches for files matching the specified name pattern in the current directory and subdirectories.
    .PARAMETER name
        The pattern to search for in file names.
    .EXAMPLE
        ff 'report'
  #>
  # ff -> Find files recursively
  Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object { Write-Output "$($_.FullName)" } 
}

function Get-PublicIP { 
  <#
    .SYNOPSIS
        Gets the public IP address.
    .DESCRIPTION
        Retrieves the public IP address of the current machine using an external web service.
    .EXAMPLE
        Get-PublicIP
  #>
  # Get-PublicIP -> Get the public IP address
  (Invoke-WebRequest http://ifconfig.me/ip).Content 
}

function Update-Profile { 
  <#
    .SYNOPSIS
        Reloads the current user's PowerShell profile.
    .DESCRIPTION
        Invokes the current profile script to reload any changes made.
    .EXAMPLE
        Update-Profile
  #>
  # Update-Profile -> Reload the current user's PowerShell profile
  & $profile 
}

function uptime {
  <#
    .SYNOPSIS
        Displays system uptime in a *NIX-style format.
    .DESCRIPTION
        Calculates and displays the time since the last system boot, including days, hours, minutes, and seconds.
    .EXAMPLE
        uptime
  #>
  # uptime(): *NIX-style uptime 
  # uptime(): *NIX-style uptime 
  try {
    # find date/time format
    # find date/time format
    $dateFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.ShortDatePattern
    $timeFormat = [System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.LongTimePattern
		
    # check powershell version
    # check powershell version
    if ($PSVersionTable.PSVersion.Major -eq 5) {
      $lastBoot = (Get-WmiObject win32_operatingsystem).LastBootUpTime
      $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)

      # reformat lastBoot
      $lastBoot = $bootTime.ToString("$dateFormat $timeFormat")
    }
    else {
      $lastBoot = net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
      $bootTime = [System.DateTime]::ParseExact($lastBoot, "$dateFormat $timeFormat", [System.Globalization.CultureInfo]::InvariantCulture)
    }

    # Format the start time
    $formattedBootTime = $bootTime.ToString("dddd, MMMM dd, yyyy HH:mm:ss", [System.Globalization.CultureInfo]::InvariantCulture) + " [$lastBoot]"
    Write-Host "System started on: $formattedBootTime" -ForegroundColor DarkGray

    # calculate uptime
    $uptime = (Get-Date) - $bootTime

    # Uptime in days, hours, minutes, and seconds
    $days = $uptime.Days
    $hours = $uptime.Hours
    $minutes = $uptime.Minutes
    $seconds = $uptime.Seconds

    # Uptime output
    Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f $days, $hours, $minutes, $seconds) -ForegroundColor Blue

  }
  catch {
    Write-Error "An error occurred while retrieving system uptime."
  }
}

function Update-PowerShell {
  <#
    .SYNOPSIS
        Updates to the latest PowerShell 7.x release.
    .DESCRIPTION
        Checks for the latest PowerShell release on GitHub and updates if a newer version is available.
    .EXAMPLE
        Update-PowerShell
  #>
  # Update-PowerShell(): Update to the latest PowerShell 7.x release
  try {
    Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
    $updateNeeded = $false
    $currentVersion = $PSVersionTable.PSVersion.ToString()
    $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
    $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
    if ($currentVersion -lt $latestVersion) {
      $updateNeeded = $true
    }
    
    if ($updateNeeded) {
      Write-Host "Updating PowerShell..." -ForegroundColor Yellow
      Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
      Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
    }
    else {
      Write-Host "Your PowerShell is up to date." -ForegroundColor Green
    }
  }
  catch {
    Write-Error "Failed to update PowerShell. Error: $_"
  }
}

function Clear-Cache {
  <#
    .SYNOPSIS
        Clears Windows Prefetch, Temp, and browser cache contents.
    .DESCRIPTION
        Removes files from various system and user cache locations to free up space and improve performance.
    .EXAMPLE
        Clear-Cache
  #>
  # Clear-Cache(): Clear Windows Prefetch, Temp and Browser cache contents
  # add clear cache logic here
  Write-Host "Clearing cache..." -ForegroundColor Cyan

  # Clear Windows Prefetch
  Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
  Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

  # Clear Windows Temp
  Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
  Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

  # Clear User Temp
  Write-Host "Clearing User Temp..." -ForegroundColor Yellow
  Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

  # Clear Internet Explorer Cache
  Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
  Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

  Write-Host "Cache clearing completed." -ForegroundColor Green
}

function unzip ($file) {
  <#
    .SYNOPSIS
        Extracts a zip file to the current directory.
    .DESCRIPTION
        Uses Expand-Archive to extract the specified zip file to the present working directory.
    .PARAMETER file
        The name of the zip file to extract.
    .EXAMPLE
        unzip 'archive.zip'
  #>
  Write-Output("Extracting", $file, "to", $pwd)
  $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
  Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function hb {
  <#
    .SYNOPSIS
        Uploads a file to a hastebin-like service.
    .DESCRIPTION
        Reads the contents of a file and uploads it to a pastebin service, returning the URL and copying it to the clipboard.
    .EXAMPLE
        hb 'script.ps1'
  #>
  if ($args.Length -eq 0) {
    Write-Error "No file path specified."
    return
  }
    
  $FilePath = $args[0]
    
  if (Test-Path $FilePath) {
    $Content = Get-Content $FilePath -Raw
  }
  else {
    Write-Error "File path does not exist."
    return
  }
    
  $uri = "http://bin.christitus.com/documents"
  try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
    $hasteKey = $response.key
    $url = "http://bin.christitus.com/$hasteKey"
    Set-Clipboard $url
    Write-Output $url
  }
  catch {
    Write-Error "Failed to upload the document. Error: $_"
  }
}
function grep($regex, $dir) {
  <#
    .SYNOPSIS
        Searches for a regex pattern in files.
    .DESCRIPTION
        Uses Select-String to search for a regular expression in files within a directory or from pipeline input.
    .PARAMETER regex
        The regex pattern to search for.
    .PARAMETER dir
        The directory to search in. If omitted, searches pipeline input.
    .EXAMPLE
        grep 'pattern' 'C:\Logs'
  #>
  if ( $dir ) {
    Get-ChildItem $dir | select-string $regex
    return
  }
  $input | select-string $regex
}

function df {
  <#
    .SYNOPSIS
        Displays volume information.
    .DESCRIPTION
        Shows information about all volumes on the system using Get-Volume.
    .EXAMPLE
        df
  #>
  get-volume
}

function sed($file, $find, $replace) {
  <#
    .SYNOPSIS
        Replaces text in a file.
    .DESCRIPTION
        Replaces all occurrences of a string in a file with another string.
    .PARAMETER file
        The file to perform replacements in.
    .PARAMETER find
        The string to find.
    .PARAMETER replace
        The string to replace with.
    .EXAMPLE
        sed 'file.txt' 'foo' 'bar'
  #>
  (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
  <#
    .SYNOPSIS
        Shows the path or definition of a command.
    .DESCRIPTION
        Uses Get-Command to display the definition or path of the specified command.
    .PARAMETER name
        The name of the command to look up.
    .EXAMPLE
        which 'git'
  #>
  Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
  <#
    .SYNOPSIS
        Sets an environment variable.
    .DESCRIPTION
        Sets or updates an environment variable for the current session.
    .PARAMETER name
        The name of the environment variable.
    .PARAMETER value
        The value to set for the environment variable.
    .EXAMPLE
        export 'MYVAR' 'myvalue'
  #>
  set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
  <#
    .SYNOPSIS
        Kills processes by name.
    .DESCRIPTION
        Stops all processes matching the specified name.
    .PARAMETER name
        The name of the process to kill.
    .EXAMPLE
        pkill 'notepad'
  #>
  Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
  <#
    .SYNOPSIS
        Lists processes by name.
    .DESCRIPTION
        Gets all processes matching the specified name.
    .PARAMETER name
        The name of the process to list.
    .EXAMPLE
        pgrep 'chrome'
  #>
  Get-Process $name
}

function head {
  <#
    .SYNOPSIS
        Displays the first n lines of a file.
    .DESCRIPTION
        Reads and displays the first n lines of the specified file.
    .PARAMETER Path
        The path to the file.
    .PARAMETER n
        The number of lines to display. Default is 10.
    .EXAMPLE
        head -Path 'file.txt' -n 5
  #>
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  <#
    .SYNOPSIS
        Displays the last n lines of a file.
    .DESCRIPTION
        Reads and displays the last n lines of the specified file, optionally following new lines as they are added.
    .PARAMETER Path
        The path to the file.
    .PARAMETER n
        The number of lines to display. Default is 10.
    .PARAMETER f
        Switch to follow the file as it grows (like tail -f).
    .EXAMPLE
        tail -Path 'file.txt' -n 20 -f
  #>
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { 
  <#
    .SYNOPSIS
        Creates a new file in the current directory.
    .DESCRIPTION
        Uses New-Item to create a new file with the specified name in the current directory.
    .PARAMETER name
        The name of the file to create.
    .EXAMPLE
        nf 'notes.txt'
  #>
  param($name) New-Item -ItemType "file" -Path . -Name $name 
}

# Directory Management
function mkcd { 
  <#
    .SYNOPSIS
        Creates and changes to a new directory.
    .DESCRIPTION
        Creates a new directory (if it doesn't exist) and sets it as the current location.
    .PARAMETER dir
        The name of the directory to create and change to.
    .EXAMPLE
        mkcd 'Projects'
  #>
  param($dir) mkdir $dir -Force; Set-Location $dir 
}

function trash($path) {
  <#
    .SYNOPSIS
        Moves a file or directory to the Recycle Bin.
    .DESCRIPTION
        Uses the Shell.Application COM object to move the specified file or directory to the Windows Recycle Bin.
    .PARAMETER path
        The path to the file or directory to move to the Recycle Bin.
    .EXAMPLE
        trash 'oldfile.txt'
  #>
  $fullPath = (Resolve-Path -Path $path).Path

  if (Test-Path $fullPath) {
    $item = Get-Item $fullPath

    if ($item.PSIsContainer) {
      # Handle directory
      $parentPath = $item.Parent.FullName
    }
    else {
      # Handle file
      $parentPath = $item.DirectoryName
    }

    $shell = New-Object -ComObject 'Shell.Application'
    $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

    if ($item) {
      $shellItem.InvokeVerb('delete')
      Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
    }
    else {
      Write-Host "Error: Could not find the item '$fullPath' to trash."
    }
  }
  else {
    Write-Host "Error: Item '$fullPath' does not exist."
  }
}

### Quality of Life Aliases

# Navigation Shortcuts
function docs { 
  <#
    .SYNOPSIS
        Changes to the user's Documents folder.
    .DESCRIPTION
        Sets the current location to the user's Documents folder.
    .EXAMPLE
        docs
  #>
  $docs = if (([Environment]::GetFolderPath("MyDocuments"))) { ([Environment]::GetFolderPath("MyDocuments")) } else { $HOME + "\Documents" }
  Set-Location -Path $docs
}
    
function dtop { 
  <#
    .SYNOPSIS
        Changes to the user's Desktop folder.
    .DESCRIPTION
        Sets the current location to the user's Desktop folder.
    .EXAMPLE
        dtop
  #>
  $dtop = if ([Environment]::GetFolderPath("Desktop")) { [Environment]::GetFolderPath("Desktop") } else { $HOME + "\Documents" }
  Set-Location -Path $dtop
}

# Simplified Process Management
function k9 { 
  <#
    .SYNOPSIS
        Kills a process by name.
    .DESCRIPTION
        Stops the process with the specified name.
    .EXAMPLE
        k9 'notepad'
  #>
  Stop-Process -Name $args[0] 
}

# Enhanced Listing
function la { 
  <#
    .SYNOPSIS
        Lists files with details in a table format.
    .DESCRIPTION
        Uses Get-ChildItem and Format-Table to display files and directories in the current location.
    .EXAMPLE
        la
  #>
  Get-ChildItem | Format-Table -AutoSize 
}
function ll { 
  <#
    .SYNOPSIS
        Lists all files (including hidden) with details in a table format.
    .DESCRIPTION
        Uses Get-ChildItem -Force and Format-Table to display all files and directories, including hidden ones.
    .EXAMPLE
        ll
  #>
  Get-ChildItem -Force | Format-Table -AutoSize 
}

# Git Shortcuts
function gs { 
  <#
    .SYNOPSIS
        Shows the status of the current Git repository.
    .DESCRIPTION
        Runs 'git status' to display the current state of the repository.
    .EXAMPLE
        gs
  #>
  git status 
}

function ga { 
  <#
    .SYNOPSIS
        Adds all changes to the Git staging area.
    .DESCRIPTION
        Runs 'git add .' to stage all changes in the current repository.
    .EXAMPLE
        ga
  #>
  git add . 
}

function gc {
  <#
    .SYNOPSIS
        Commits staged changes with a message.
    .DESCRIPTION
        Runs 'git commit -m' with the provided message to commit staged changes.
    .PARAMETER m
        The commit message.
    .EXAMPLE
        gc -m 'Initial commit'
  #>
  param($m) git commit -m "$m" 
}

function gp { 
  <#
    .SYNOPSIS
        Pushes committed changes to the remote Git repository.
    .DESCRIPTION
        Runs 'git push' to upload local commits to the remote repository.
    .EXAMPLE
        gp
  #>
  git push 
}

function gcl {
  <#
    .SYNOPSIS
        Clones a Git repository.
    .DESCRIPTION
        Runs 'git clone' with the specified arguments to clone a repository.
    .EXAMPLE
        gcl 'https://github.com/user/repo.git'
  #>
  git clone "$args" 
}

function gcom {
  <#
    .SYNOPSIS
        Adds, commits, and optionally pushes changes in Git.
    .DESCRIPTION
        Runs 'git add .', 'git commit -m', and optionally 'git push' with the provided arguments.
    .EXAMPLE
        gcom 'Update README'
  #>
  {
    git add .
    git commit -m "$args"
  }
}
function lazyg {
  <#
    .SYNOPSIS
        Adds, commits, and pushes changes in Git in one step.
    .DESCRIPTION
        Runs 'git add .', 'git commit -m', and 'git push' with the provided arguments.
    .EXAMPLE
        lazyg 'Quick update'
  #>
  {
    git add .
    git commit -m "$args"
    git push
  }
}

# Quick Access to System Information
function sysinfo { 
  <#
    .SYNOPSIS
        Displays system information.
    .DESCRIPTION
        Uses Get-ComputerInfo to display detailed information about the system.
    .EXAMPLE
        sysinfo
  #>
  Get-ComputerInfo 
}

# Networking Utilities
function flushdns {
  <#
    .SYNOPSIS
        Clears the DNS client cache.
    .DESCRIPTION
        Runs Clear-DnsClientCache and displays a confirmation message.
    .EXAMPLE
        flushdns
  #>
  Clear-DnsClientCache
  Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cpy { 
  <#
    .SYNOPSIS
        Copies text to the clipboard.
    .DESCRIPTION
        Uses Set-Clipboard to copy the specified text to the clipboard.
    .EXAMPLE
        cpy 'Hello, world!'
  #>
  Set-Clipboard $args[0] 
}

function pst { 
  <#
    .SYNOPSIS
        Retrieves text from the clipboard.
    .DESCRIPTION
        Uses Get-Clipboard to get the current clipboard contents.
    .EXAMPLE
        pst
  #>
  Get-Clipboard 
}

function tf {
  <#
    .SYNOPSIS
        Runs the terraform command with provided arguments.
    .DESCRIPTION
        Passes all arguments to the terraform CLI tool.
    .EXAMPLE
        tf plan
  #>
  terraform $args 
}

function tfi {
  <#
    .SYNOPSIS
        Runs 'terraform init -upgrade' with provided arguments.
    .DESCRIPTION
        Initializes a Terraform working directory and upgrades modules/providers.
    .EXAMPLE
        tfi
  #>
  terraform init -upgrade $args 
}

function tfp {
  <#
    .SYNOPSIS
        Runs 'terraform plan' with provided arguments.
    .DESCRIPTION
        Creates an execution plan for Terraform.
    .EXAMPLE
        tfp
  #>
  terraform plan $args 
}

function tfa {
  <#
    .SYNOPSIS
        Runs 'terraform apply -auto-approve' with provided arguments.
    .DESCRIPTION
        Applies Terraform changes without prompting for approval.
    .EXAMPLE
        tfa
  #>
  terraform apply -auto-approve $args 
}

function tfd {
  <#
    .SYNOPSIS
        Runs 'terraform destroy -auto-approve' with provided arguments.
    .DESCRIPTION
        Destroys Terraform-managed infrastructure without prompting for approval.
    .EXAMPLE
        tfd
  #>
  terraform destroy -auto-approve $args 
}

function o {
  <#
    .SYNOPSIS
        Opens a directory in Windows Explorer.
    .DESCRIPTION
        Uses explorer.exe to open the specified directory or file.
    .EXAMPLE
        o 'C:\Users\User\Documents'
  #>
  explorer.exe $args 
}

function ll {
  <#
    .SYNOPSIS
        Lists files (including hidden) with details.
    .DESCRIPTION
        Uses Get-ChildItem -Force to list all files and directories, including hidden ones.
    .EXAMPLE
        ll
  #>
  Get-ChildItem $args -Force
}

Set-Alias -Name "huh" -Value Show-Features
#endregion

#region Main()
# ╭────────────────────────────────╮
# │ Profile Processing begins here │
# ╰────────────────────────────────╯
#opt-out of telemetry before doing anything, only if PowerShell is run as admin
if ([bool]([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
  [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::Machine)
}

# Initial GitHub.com connectivity check with 1 second timeout
$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Ensure Terminal-Icons module is installed before importing 
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
  try {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
  }
  catch {
    if ($debug) {
      Print-RBox "$($PSStyle.Foreground.Red)Failed to install Terminal-Icons module. Error: $_"
    }
  }
}
else {
  try {
    Import-Module -Name Terminal-Icons -Force
  }
  catch {
    if ($debug) {
      Print-RBox "$($PSStyle.Foreground.Red)Failed to import Terminal-Icons module. Error: $_"
    }
  }
}

# Import the $ChocolateyProfile PSM1 if available 
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}


# function prompt {
#   if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
# }
# $adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
# $Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# # Utility Functions
# function Test-CommandExists {
#   param($command)
#   $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
#   return $exists
# }

# # Editor Configuration
# $EDITOR = if (Test-CommandExists nvim) { 'nvim' }
# elseif (Test-CommandExists pvim) { 'pvim' }
# elseif (Test-CommandExists vim) { 'vim' }
# elseif (Test-CommandExists vi) { 'vi' }
# elseif (Test-CommandExists code) { 'code' }
# elseif (Test-CommandExists notepad++) { 'notepad++' }
# elseif (Test-CommandExists sublime_text) { 'sublime_text' }
# else { 'notepad' }
# Set-Alias -Name vim -Value $EDITOR

# # System Utilities
# function admin {
#   if ($args.Count -gt 0) {
#     $argList = $args -join ' '
#     Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
#   }
#   else {
#     Start-Process wt -Verb runAs
#   }
# }

# # Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
# Set-Alias -Name su -Value admin



# Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
  EditMode                      = 'Windows'
  HistoryNoDuplicates           = $true
  HistorySearchCursorMovesToEnd = $true
  Colors                        = @{
    Command   = '#87CEEB'  # SkyBlue (pastel)
    Parameter = '#98FB98'  # PaleGreen (pastel)
    Operator  = '#FFB6C1'  # LightPink (pastel)
    Variable  = '#DDA0DD'  # Plum (pastel)
    String    = '#FFDAB9'  # PeachPuff (pastel)
    Number    = '#B0E0E6'  # PowderBlue (pastel)
    Type      = '#F0E68C'  # Khaki (pastel)
    Comment   = '#D3D3D3'  # LightGray (pastel)
    Keyword   = '#8367c7'  # Violet (pastel)
    Error     = '#FF6347'  # Tomato (keeping it close to red for visibility)
  }
  PredictionSource              = 'History'
  PredictionViewStyle           = 'ListView'
  BellStyle                     = 'None'
}
Set-PSReadLineOption @PSReadLineOptions

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# Custom functions for PSReadLine
Set-PSReadLineOption -AddToHistoryHandler {
  param($line)
  $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
  $hasSensitive = $sensitive | Where-Object { $line -match $_ }
  return ($null -eq $hasSensitive)
}

# Improved prediction settings
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -MaximumHistoryCount 10000

# Custom completion for common commands
$scriptblock = {
  param($wordToComplete, $commandAst, $cursorPosition)
  $customCompletions = @{
    'git'  = @('status', 'add', 'commit', 'push', 'pull', 'clone', 'checkout')
    'npm'  = @('install', 'start', 'run', 'test', 'build')
    'deno' = @('run', 'compile', 'bundle', 'test', 'lint', 'fmt', 'cache', 'info', 'doc', 'upgrade')
  }
    
  $command = $commandAst.CommandElements[0].Value
  if ($customCompletions.ContainsKey($command)) {
    $customCompletions[$command] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
  }
}
Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock $scriptblock

$scriptblock = {
  param($wordToComplete, $commandAst, $cursorPosition)
  dotnet complete --position $cursorPosition $commandAst.ToString() |
  ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

# ╭───────────────────────────╮
# │ Winget argument completer │
# ╰───────────────────────────╯
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
  $Local:word = $wordToComplete.Replace('"', '""')
  $Local:ast = $commandAst.ToString().Replace('"', '""')
  winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

# ╭──────────────────────────╮
# │ Choco argument completer │
# ╰──────────────────────────╯
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# ╭─────────────────────────────────╮
# │ Oh-My-Posh default prompt theme │
# ╰─────────────────────────────────╯
# oh-my-posh init pwsh | Invoke-Expression
# oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
oh-my-posh init pwsh --config https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/cloud-native-azure.omp.json | Invoke-Expression

# ╭─────╮
# │ Fin │
# ╰─────╯
$profileLoadEnd = Get-Date
$profileLoadDuration = $profileLoadEnd - $profileLoadStart
Write-Host "Loaded `$PROFILE: $PROFILE in $profileLoadDuration.TotalSeconds" -ForegroundColor DarkGray
Write-RBox "Run $($PSStyle.Foreground.Yellow)Show-Features$($PSStyle.Reset) to display the list of supported features."
