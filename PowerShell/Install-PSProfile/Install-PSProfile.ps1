# Install-PSProfile.ps1
# Deploys PowerShell profile scripts from the project to the user's profile locations

$projectProfileDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sourceProfile = Join-Path $projectProfileDir 'Microsoft.PowerShell_profile.ps1'

# Get user profile paths
$pwshProfile = $PROFILE.CurrentUserAllHosts
$windowsPowerShellProfile = [Environment]::GetFolderPath('MyDocuments') + '\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'

function Copy-Profile {
  param (
    [string]$Source,
    [string]$Destination
  )
  if (Test-Path $Source) {
    $destDir = Split-Path $Destination -Parent
    if (-not (Test-Path $destDir)) {
      New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    Copy-Item -Path $Source -Destination $Destination -Force
    Write-Host "Deployed profile to $Destination"
  } else {
    Write-Warning "Source profile '$Source' not found."
  }
}

# Deploy to PowerShell 7+ profile
Copy-Profile -Source $sourceProfile -Destination $pwshProfile

# Deploy to Windows PowerShell 5.1 profile (if different)
if ($pwshProfile -ne $windowsPowerShellProfile) {
  Copy-Profile -Source $sourceProfile -Destination $windowsPowerShellProfile
}

Write-Host "Profile installation complete."