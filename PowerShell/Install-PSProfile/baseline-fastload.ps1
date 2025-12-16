# ╭─────────────────────────────────────╮
# │ PowerShell 7.x Profile - Windows    │
# ╰─────────────────────────────────────╯

$profileLoadStart = Get-Date

$Global:ProfileFeatures = @()

#region Globals... 
# Set the debug mode.  Use $DebugPreference for more control.
$DebugPreference = 'SilentlyContinue' # Or: 'Continue', 'Stop', 'Inquire'

# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
#endregion

#region Helper Functions...
# ╭──────────────────╮
# │ Helper Functions │
# ╰──────────────────╯
function Write-RBox {
  <#
    .SYNOPSIS
        Displays a multi-line string within a decorated box.
    .DESCRIPTION
        This function takes a string, splits it into lines, and displays it
        within a box constructed of ASCII characters. It handles ANSI
        escape codes for colored output and adjusts the box size to fit
        the longest line.
    .PARAMETER Text
        The string to display within the box. Newlines (`n) are
        interpreted as line breaks.
    .PARAMETER BorderColor
        The color of the box border. Default is Cyan.
        Use $PSStyle.Foreground.<ColorName> to set the color.
    .EXAMPLE
        Write-RBox -Text "This is a test`nwith multiple lines."
  #>
  param (
    [string]$Text,
    [string]$BorderColor = $PSStyle.Foreground.Cyan,
    [int]$Column = 2,
    [int]$Padding = 1
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
  $Spaces = ($MaxLength + ($Padding * 2))

  # Print the top border
  Write-Host (' ' * $Column) -NoNewline
  Write-Host "$($BorderColor)╭$('─' * $($Spaces))╮$($RstC)"

  # Print the lines inside the box
  foreach ($Line in $Lines) {
    if ($Line.Contains("#divider#")) {
      Write-Host (' ' * $Column) -NoNewline
      Write-Host "$($BorderColor)├$('$($BorderColor)─' * $($Spaces))$($BorderColor)┤$($RstC)"
    }
    else {
      $LBorder = "$($BorderColor)│$($RstC)" + (' ' * $Padding)
      $RBorder = (' ' * $Padding) + "$($BorderColor)│$($RstC)"
      $PrintableLine = $Line -replace "`e\[[\d;]*m", ''
      $PadSpaces = $(' ' * $($MaxLength - $PrintableLine.Length))
      Write-Host (' ' * $Column) -NoNewline
      Write-Host "$($LBorder)$($Line)$($PadSpaces)$($RBorder)"
    }
  }
  # Print the bottom border
  Write-Host (' ' * $Column) -NoNewline
  Write-Host "$($BorderColor)╰$('─' * $($Spaces))╯$($RstC)"
}

function Get-TaggedCommands {
  param(
    [string]$Tag = '#feature'
  )

  # Get the path of the current script file
  $scriptPath = $PROFILE

  # Get only the functions and aliases from the current script
  $allCommands = Get-Command -CommandType Function, Alias | Where-Object { $_.ScriptBlock.File -eq $scriptPath }

  # Filter the commands
  $Commands = foreach ($command in $allCommands) {
    # Get the actual command behind an alias
    $resolvedCommand = if ($command.CommandType -eq 'Alias') {
      Get-Command $command.ResolvedCommandName -ErrorAction SilentlyContinue
    }
    else {
      $command
    }

    # Ensure we have a valid function with a script block
    if ($null -ne $resolvedCommand -and $resolvedCommand.ScriptBlock) {
      # Get the content of the script
      $scriptContent = Get-Content -Path $resolvedCommand.ScriptBlock.File -Raw

      # Check if the synopsis contains the tag
      if ($scriptContent -match "(?s)<#\s*\.SYNOPSIS\s+(.*?($Tag).*?)\s*#>") {
        $command
      }
    }
  }

  return $Commands
}

function Show-Features {
  [CmdletBinding()]
  param (
    [Switch]$PassThru
  )

  # Decoration variables
  $SecC = $PSStyle.Foreground.BrightWhite
  $FunC = $PSStyle.Foreground.BrightYellow
  $ParC = $PSStyle.Foreground.Green + $PSStyle.Italic
  $RstC = $PSStyle.Reset
  $DimC = $PSStyle.Dim
  
  # Configuration
  $config = @{
    Column = 2
    Padding = 1
    MaxWidth = 80
  }

  # Part 1: Define the features of the profile script itself.
  $CoreProfileFeatures = @"
`n$($SecC)PowerShell Profile Help$($RstC)

$($SecC)   Host:$($RstC) $($Host.Name)
$($SecC)Profile:$($RstC) $PROFILE
#divider#
"@

  # Part 2: If -PassThru is used, just return the core features.
  if ($PassThru) {
    return $CoreProfileFeatures
  }

  # Part 3: Aggregate features for display.
  $AllFeatures = [System.Text.StringBuilder]::new()
  $AllFeatures.AppendLine($CoreProfileFeatures) | Out-Null

  $TaggedCommands = Get-TaggedCommands
  if ($TaggedCommands) {
    $AllFeatures.AppendLine("$($SecC)Available Commands:$($RstC)") | Out-Null
    foreach ($Command in $TaggedCommands) {
      $Synopsis = (Get-Help $Command -Full).Synopsis -replace '#feature'
      $AllFeatures.AppendLine("  $($FunC)$($Command.Name)$($RstC) - $($Synopsis)") | Out-Null
    }
  }

  # Find other modules with Show-Features and append their output.
  $Modules = Get-Module -ListAvailable | Where-Object { $_.Name -ne 'Microsoft.PowerShell.Core' }
  foreach ($Module in $Modules) {
      $ShowFeaturesCmd = Get-Command -Module $Module.Name -Name Show-Features -ErrorAction SilentlyContinue
      if ($ShowFeaturesCmd) {
          try {
              $Features = & $ShowFeaturesCmd -PassThru
              if ($Features) {
                  $AllFeatures.AppendLine($Features) | Out-Null
              }
          } catch {
              Write-Warning "Failed to get features from module $($Module.Name): $_"
          }
      }
  }
  
  $AllFeatures.AppendLine("#divider#") | Out-Null
  $AllFeatures.AppendLine("💡TIP: Run $($FunC)Get-Help  $($ParC)[function]$($RstC) on most of these functions will display more information.") | Out-Null

  # Part 4: Display the aggregated features.
  Write-RBox -Text $AllFeatures.ToString() -Column $config.Column -Padding $config.Padding
}
#endregion

#region PSProfile Management...
#endregion

#region Aliases & Functions...
# Aliases & Functions...
# ╭─────────────────────╮
# │ Aliases & Functions │
# ╰─────────────────────╯

# tf: Runs 'terraform' with provided args. Ex: tf plan || See 'tfp'
function tf { terraform $args }

# tfi: Runs 'terraform init' with provided args. Ex: tfi 
function tfi { terraform init -upgrade }

# tfp: Runs 'terraform plan' with provided arguments. Ex: tfp
function tfp { terraform plan $args }

# tfa: Runs 'terraform apply -auto-approve' with provided arguments.
function tfa { terraform apply -auto-approve $args }

# tfd: Runs 'terraform destroy -auto-approve' with provided arguments. 
function tfd { terraform destroy -auto-approve $args }

# o: Opens a directory in Windows explorer. Ex: o $env:USERPROFILE (profile dir)
function o { explorer.exe $args }

# ll: Lists files (including hidden) with details
function ll { Get-ChildItem $args -Force }

# nano: Open file in terminal using WSL's nano editor. Ex: nano ./package.json || nano d:\path\test.txt
function nano { 
  if (get-command bash) {
    $nFile = $args[0] -replace '^([A-Za-z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" } -replace '\\', '/'
    bash -c "nano $($nFile)"
  } else {
    Write-Host "'bash' command not found. Check your WSL configuration"
  }
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
if (Get-Command oh-my-posh) {
  oh-my-posh init pwsh --config http/raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
  # oh-my-posh init pwsh --config https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/cloud-native-azure.omp.json | Invoke-Expression
}

# ╭───────────────╮
# │ Run fastfetch │
# ╰───────────────╯
if (get-command fastfetch) {
  fastfetch # -c [path_to_jsonc]; See 'fastfetch --gen-config'
}

# ╭─────╮
# │ Fin │
# ╰─────╯
Write-RBox "💡 TIP: Run $($PSStyle.Foreground.Yellow)Show-Features$($PSStyle.Reset) or $($PSStyle.Foreground.Yellow)huh$($PSStyle.Reset) to show what your profile provides."
$profileLoadEnd = Get-Date
$profileLoadDuration = $profileLoadEnd - $profileLoadStart
Write-Host "Load Duration: [$([math]::Round($profileLoadDuration.TotalMilliseconds)) ms]" -ForegroundColor DarkGray
#endregion
