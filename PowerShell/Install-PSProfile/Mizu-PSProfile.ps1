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

  $Commands = Get-Command -CommandType Function,Alias | Where-Object {
    (Get-Help $_ -Full).Synopsis -match $Tag
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
}"─" * $($Spaces))╮$($RstC)"

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
        This function displays a formatted help message, including
        available aliases, functions, and their descriptions.  It uses
        the Write-RBox function to present the information in a
        user-friendly box.

    .EXAMPLE
        Show-Help
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
#endregion

#region Aliases & Functions...
# ╭─────────────────────╮
# │ Aliases & Functions │
# ╰─────────────────────╯
<#
.SYNOPSIS
#feature
Runs 'terraform' with provided args. Ex: tf plan || See 'tfp'
#>
function tf { terraform $args }

<#
.SYNOPSIS
#feature
Runs 'terraform init' with provided args. Ex: tfi 
#>
function tfi { terraform init -upgrade $args }
# set-alias -Name "tfi"  -Value func-tfi

<#
.SYNOPSIS
#feature
Runs 'terraform plan' with provided arguments. Ex: tfp
#>
function tfp { terraform plan $args }
# set-alias -Name "tfp"  -Value func-tfp

<#
.SYNOPSIS
#feature
Runs 'terraform apply -auto-approve' with provided arguments.
#>
function tfa { terraform apply -auto-approve $args }
# set-alias -Name "tfa"  -Value func-tfa

<#
.SYNOPSIS
#feature
Runs 'terraform destroy -auto-approve' with provided arguments. 
#>
function tfd { terraform destroy -auto-approve $args }

<#
.SYNOPSIS
#feature
Opens a directory in Windows explorer. Ex: o $env:USERPROFILE (profile dir)
#>
function o { explorer.exe $args }

<#
.SYNOPSIS
#feature
Lists files (including hidden) with details
#>
function ll { Get-ChildItem $args -Force}

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
oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
# oh-my-posh init pwsh --config https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/cloud-native-azure.omp.json | Invoke-Expression

# ╭─────╮
# │ Fin │
# ╰─────╯
Write-RBox "💡TIP: Run $($PSStyle.Foreground.Yellow)Show-Features$($PSStyle.Reset) or $($PSStyle.Foreground.Yellow)huh$($PSStyle.Reset) to show what your profile provides."
$profileLoadEnd = Get-Date
$profileLoadDuration = $profileLoadEnd - $profileLoadStart
Write-Host " "
Write-Host "Load Duration: [$([math]::Round($profileLoadDuration.TotalMilliseconds)) ms]" -ForegroundColor DarkGray
#endregion