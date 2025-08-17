param(
    [string]$ShortcutName = "*",
    [switch]$AllUsers
)

<#
.SYNOPSIS
    Extracts command, parameters, and working directory from Start Menu shortcuts.

.DESCRIPTION
    This script searches for shortcuts in the Start Menu and extracts their properties
    including target path, arguments, and working directory.

.PARAMETER ShortcutName
    Name of the shortcut to search for. Supports wildcards. Default is "*" (all shortcuts).

.PARAMETER AllUsers
    Include shortcuts from the All Users Start Menu in addition to current user shortcuts.

.EXAMPLE
    .\Get-StartMenuShortcuts.ps1 -ShortcutName "Notepad*"
    
.EXAMPLE
    .\Get-StartMenuShortcuts.ps1 -AllUsers
#>

function Get-ShortcutInfo {
    param(
        [string]$ShortcutPath
    )
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        
        [PSCustomObject]@{
            Name = [System.IO.Path]::GetFileNameWithoutExtension($ShortcutPath)
            ShortcutPath = $ShortcutPath
            TargetPath = $Shortcut.TargetPath
            Arguments = $Shortcut.Arguments
            WorkingDirectory = $Shortcut.WorkingDirectory
            Description = $Shortcut.Description
            IconLocation = $Shortcut.IconLocation
            WindowStyle = $Shortcut.WindowStyle
            Hotkey = $Shortcut.Hotkey
        }
    }
    catch {
        Write-Warning "Failed to read shortcut: $ShortcutPath - $($_.Exception.Message)"
        return $null
    }
}

# Define Start Menu paths
$StartMenuPaths = @()

# Current user Start Menu
$CurrentUserStartMenu = [Environment]::GetFolderPath('StartMenu')
$StartMenuPaths += $CurrentUserStartMenu

# All Users Start Menu (if requested)
if ($AllUsers) {
    $AllUsersStartMenu = [Environment]::GetFolderPath('CommonStartMenu')
    $StartMenuPaths += $AllUsersStartMenu
}

Write-Host "Searching for shortcuts matching: $ShortcutName" -ForegroundColor Green
Write-Host "Search paths:" -ForegroundColor Yellow
$StartMenuPaths | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host ""

$AllShortcuts = @()

foreach ($StartMenuPath in $StartMenuPaths) {
    if (Test-Path $StartMenuPath) {
        # Find all .lnk files recursively
        $ShortcutFiles = Get-ChildItem -Path $StartMenuPath -Filter "*.lnk" -Recurse | 
                        Where-Object { $_.Name -like "$ShortcutName.lnk" -or $ShortcutName -eq "*" }
        
        foreach ($ShortcutFile in $ShortcutFiles) {
            $ShortcutInfo = Get-ShortcutInfo -ShortcutPath $ShortcutFile.FullName
            if ($ShortcutInfo) {
                $AllShortcuts += $ShortcutInfo
            }
        }
    }
}

# Display results
if ($AllShortcuts.Count -eq 0) {
    Write-Host "No shortcuts found matching the criteria." -ForegroundColor Red
} else {
    Write-Host "Found $($AllShortcuts.Count) shortcut(s):" -ForegroundColor Green
    Write-Host ""
    
    foreach ($Shortcut in $AllShortcuts) {
        Write-Host "=== $($Shortcut.Name) ===" -ForegroundColor Cyan
        Write-Host "Shortcut Path:    $($Shortcut.ShortcutPath)" -ForegroundColor Gray
        Write-Host "Target Command:   $($Shortcut.TargetPath)" -ForegroundColor White
        Write-Host "Parameters:       $($Shortcut.Arguments)" -ForegroundColor White
        Write-Host "Working Directory: $($Shortcut.WorkingDirectory)" -ForegroundColor White
        
        if ($Shortcut.Description) {
            Write-Host "Description:      $($Shortcut.Description)" -ForegroundColor Gray
        }
        if ($Shortcut.IconLocation) {
            Write-Host "Icon Location:    $($Shortcut.IconLocation)" -ForegroundColor Gray
        }
        if ($Shortcut.Hotkey) {
            Write-Host "Hotkey:           $($Shortcut.Hotkey)" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
}

# Output as objects for further processing
return $AllShortcuts
