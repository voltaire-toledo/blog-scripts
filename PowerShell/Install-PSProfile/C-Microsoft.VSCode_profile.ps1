# ╭─────────────────────────────────────╮
# │ ╭─────────────────────────────────╮ │
# │ │PowerShell 7.x Profile - VSCode  │ │
# │ ╰─────────────────────────────────╯ │
# ╰─────────────────────────────────────╯
# ╭───────────────────────────────────────────╮
# │ Helper Function: Write-RBox(string)       │
# │                  RBox a Multi-Line String │
# ╰───────────────────────────────────────────╯
function Write-RBox {
  <#
    .SYNOPSIS
        Displays a multi-line string within a decorated box.

    .DESCRIPTION
        This function takes a string, splits it into lines, and displays it
        within a box constructed of ASCII characters.  It handles ANSI
        escape codes for colored output and adjusts the box size to fit
        the longest line.

    .PARAMETER Text
        The string to display within the box.  Newlines (`n) are
        interpreted as line breaks.
    .PARAMETER BorderColor
        The color of the box border.  Default is Cyan.
        Use $PSStyle.Foreground.<ColorName> to set the color.

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
  Write-Host "$($PSStyle.Foreground.Cyan)╰$("─" * $($Spaces))$($PSStyle.Foreground.Cyan)╯"
}

# ╭──────────────────────────────╮
# │ Helper Function: Show-Help() │
# ╰──────────────────────────────╯
function Show-Help {
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
  $SecC = $PSStyle.Foreground.BrightMagenta
  $FunC = $PSStyle.Foreground.BrightYellow
  $ParC = $PSStyle.Foreground.Green
  $RstC = $PSStyle.Reset

  # Use here-string for better multi-line string handling
  $HelpText = @"
$($SecC)PowerShell Profile Help - VSCode$($RstC)

$($SecC)   Host:$($RstC) $($Host.Name)
$($SecC)Profile:$($RstC) $PROFILE
#divider#
$($SecC)Features:$($RstC)
  - Winget argument completer
  - Az CLI Argument Completer
  - Choco argument completer
    
$($SecC)Terraform Aliases:
  $($FunC) tf$($RstC)                 ⁝ terraform         
  $($FunC)tfi$($RstC)                 ⁝ terraform init -upgrade        
  $($FunC)tfp$($RstC)                 ⁝ terraform plan        
  $($FunC)tfa$($RstC)                 ⁝ terraform apply -auto-approve        
  $($FunC)tfd$($RstC)                 ⁝ terraform destroy -auto-approve
"@

  # Print the help text in a box
  Write-RBox -Text $HelpText
}


########################################################################

# ╭─────────────────────────────────╮
# │ Oh-My-Posh default prompt theme │
# ╰─────────────────────────────────╯
oh-my-posh init pwsh | Invoke-Expression

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


# ╭─────────────────────╮
# │ Functions & Aliases │
# ╰─────────────────────╯
function tf { terraform $args }

function tfi { terraform init -upgrade $args }
# set-alias -Name "tfi"  -Value func-tfi

function tfp { terraform plan $args }
# set-alias -Name "tfp"  -Value func-tfp

function tfa { terraform apply -auto-approve $args }
# set-alias -Name "tfa"  -Value func-tfa

function tfd { terraform destroy -auto-approve $args }

function o { explorer.exe $args }

########################################################################

# ╭──────────────╮
# │Final Message │
# ╰──────────────╯
Write-Host " "
Write-Host "Loaded `$PROFILE: $PROFILE" -ForegroundColor DarkGray
Write-Host "Run Show-Help to display features from this `$PROFILE." -ForegroundColor Yellow
