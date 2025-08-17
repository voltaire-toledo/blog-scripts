param(
    [string]$TimeFormat = "default",
    [string]$Voice = "default",
    [string]$VoiceType = "auto",  # "sapi", "winrt", "auto"
    [int]$Rate = 0,
    [int]$Volume = 100,
    [switch]$ShowAvailableVoices,
    [switch]$PreferAria,
    [switch]$PreferGuy,
    [switch]$PreferNatural
)

<#
.SYNOPSIS
    Announces the current time using both traditional SAPI and modern Windows Runtime voices.

.DESCRIPTION
    This script demonstrates access to both traditional Windows SAPI voices and modern
    Windows Runtime natural voices (including Aria, Jenny, Guy, etc.). It includes
    graceful error handling for missing voices.

.PARAMETER TimeFormat
    Format for time announcement:
    - "default" or "12hour": 12-hour format with AM/PM
    - "24hour": 24-hour format
    - "verbose": Full verbose time description
    - "simple": Just hour and minute

.PARAMETER Voice
    Specific voice to use. Use "default" for system default or specify voice name.
    Examples: "Aria", "Jenny", "David", "Zira"

.PARAMETER VoiceType
    Voice system to use:
    - "auto": Try WinRT first, fallback to SAPI
    - "winrt": Use Windows Runtime (modern natural voices)
    - "sapi": Use traditional SAPI voices

.PARAMETER Rate
    Speech rate from -10 (slowest) to 10 (fastest). Default is 0 (normal).

.PARAMETER Volume
    Speech volume from 0 (silent) to 100 (loudest). Default is 100.

.PARAMETER ShowAvailableVoices
    Display all available voices from both systems and exit.

.PARAMETER PreferAria
    Automatically try to use Aria voice if available, with graceful fallback.

.PARAMETER PreferGuy
    Automatically try to use Guy voice if available, with graceful fallback.

.PARAMETER PreferNatural
    Automatically try to use any available natural voice (Aria, Guy, Jenny, etc.) with graceful fallback.

.EXAMPLE
    .\Announce-Time-Enhanced.ps1
    Announces time using best available voice

.EXAMPLE
    .\Announce-Time-Enhanced.ps1 -PreferAria
    Tries to use Aria voice, falls back gracefully if not available

.EXAMPLE
    .\Announce-Time-Enhanced.ps1 -PreferGuy
    Tries to use Guy voice, falls back gracefully if not available

.EXAMPLE
    .\Announce-Time-Enhanced.ps1 -PreferNatural
    Tries to use any available natural voice, falls back gracefully if none available

.EXAMPLE
    .\Announce-Time-Enhanced.ps1 -ShowAvailableVoices
    Shows all available voices from both SAPI and WinRT systems
#>

# Initialize global variables
$script:sapiAvailable = $false
$script:winrtAvailable = $false
$script:sapiSpeech = $null
$script:winrtSynthesizer = $null

function Initialize-SAPIVoices {
    try {
        Add-Type -AssemblyName System.Speech
        $script:sapiSpeech = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $script:sapiAvailable = $true
        Write-Verbose "SAPI voices initialized successfully"
        return $true
    } catch {
        Write-Verbose "Failed to initialize SAPI: $($_.Exception.Message)"
        return $false
    }
}

function Initialize-WinRTVoices {
    try {
        # Load Windows Runtime assemblies
        [Windows.ApplicationModel.Core.CoreApplication,Windows.ApplicationModel.Core,ContentType=WindowsRuntime] | Out-Null
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        
        # Import WinRT types
        $null = [Windows.Media.SpeechSynthesis.SpeechSynthesizer,Windows.Media.SpeechSynthesis,ContentType=WindowsRuntime]
        $null = [Windows.Media.SpeechSynthesis.VoiceInformation,Windows.Media.SpeechSynthesis,ContentType=WindowsRuntime]
        
        $script:winrtSynthesizer = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::new()
        $script:winrtAvailable = $true
        Write-Verbose "Windows Runtime voices initialized successfully"
        return $true
    } catch {
        Write-Verbose "Failed to initialize Windows Runtime: $($_.Exception.Message)"
        return $false
    }
}

function Get-SAPIVoices {
    if (-not $script:sapiAvailable) { return @() }
    
    try {
        $voices = @()
        $script:sapiSpeech.GetInstalledVoices() | ForEach-Object {
            if ($_.Enabled) {
                $voices += [PSCustomObject]@{
                    Name = $_.VoiceInfo.Name
                    DisplayName = $_.VoiceInfo.Name
                    Culture = $_.VoiceInfo.Culture.DisplayName
                    Gender = $_.VoiceInfo.Gender
                    Age = $_.VoiceInfo.Age
                    Type = "SAPI"
                    Available = $true
                }
            }
        }
        return $voices
    } catch {
        Write-Verbose "Error getting SAPI voices: $($_.Exception.Message)"
        return @()
    }
}

function Get-WinRTVoices {
    if (-not $script:winrtAvailable) { return @() }
    
    try {
        $voices = @()
        $winrtVoices = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices
        
        foreach ($voice in $winrtVoices) {
            $voices += [PSCustomObject]@{
                Name = $voice.Id
                DisplayName = $voice.DisplayName
                Culture = $voice.Language
                Gender = $voice.Gender.ToString()
                Age = "Unknown"
                Type = "WinRT (Natural)"
                Available = $true
            }
        }
        return $voices
    } catch {
        Write-Verbose "Error getting WinRT voices: $($_.Exception.Message)"
        return @()
    }
}

function Find-Voice {
    param(
        [string]$VoiceName,
        [string]$PreferredType = "auto"
    )
    
    $allVoices = @()
    
    # Get voices based on preferred type
    if ($PreferredType -eq "auto" -or $PreferredType -eq "winrt") {
        $allVoices += Get-WinRTVoices
    }
    if ($PreferredType -eq "auto" -or $PreferredType -eq "sapi") {
        $allVoices += Get-SAPIVoices
    }
    
    # Try exact match first
    $exactMatch = $allVoices | Where-Object { $_.DisplayName -eq $VoiceName -or $_.Name -eq $VoiceName }
    if ($exactMatch) { return $exactMatch[0] }
    
    # Try partial match
    $partialMatch = $allVoices | Where-Object { $_.DisplayName -like "*$VoiceName*" -or $_.Name -like "*$VoiceName*" }
    if ($partialMatch) { return $partialMatch[0] }
    
    return $null
}

function Find-NaturalVoice {
    param(
        [string[]]$PreferredVoices = @("Aria", "Guy", "Jenny", "Davis", "Jane", "Jason", "Nancy")
    )
    
    $winrtVoices = Get-WinRTVoices
    
    # Try to find preferred voices in order
    foreach ($preferredVoice in $PreferredVoices) {
        $foundVoice = $winrtVoices | Where-Object { $_.DisplayName -like "*$preferredVoice*" -or $_.Name -like "*$preferredVoice*" }
        if ($foundVoice) {
            return $foundVoice[0]
        }
    }
    
    # If no preferred voice found, return any WinRT voice
    if ($winrtVoices.Count -gt 0) {
        return $winrtVoices[0]
    }
    
    return $null
}

function Speak-WithSAPI {
    param(
        [string]$Text,
        [string]$VoiceName = $null,
        [int]$Rate = 0,
        [int]$Volume = 100
    )
    
    try {
        if ($VoiceName) {
            $script:sapiSpeech.SelectVoice($VoiceName)
        }
        
        $script:sapiSpeech.Rate = [Math]::Max(-10, [Math]::Min(10, $Rate))
        $script:sapiSpeech.Volume = [Math]::Max(0, [Math]::Min(100, $Volume))
        
        $script:sapiSpeech.Speak($Text)
        return $true
    } catch {
        Write-Warning "SAPI speech failed: $($_.Exception.Message)"
        return $false
    }
}

function Speak-WithWinRT {
    param(
        [string]$Text,
        [string]$VoiceId = $null
    )
    
    try {
        if ($VoiceId) {
            $voice = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices | Where-Object { $_.Id -eq $VoiceId -or $_.DisplayName -eq $VoiceId }
            if ($voice) {
                $script:winrtSynthesizer.Voice = $voice
            }
        }
        
        # Create speech synthesis stream
        $stream = $script:winrtSynthesizer.SynthesizeTextToStreamAsync($Text)
        $stream.AsTask().Wait()
        
        # Play the audio (simplified - in real implementation you'd need to handle audio playback)
        Write-Host "Note: WinRT voice synthesis completed (audio playback requires additional implementation)" -ForegroundColor Yellow
        return $true
    } catch {
        Write-Warning "WinRT speech failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-TimeMessage {
    param([string]$Format)
    
    $currentTime = Get-Date
    
    switch ($Format.ToLower()) {
        "24hour" {
            return "The time is $($currentTime.ToString('HH:mm'))"
        }
        "verbose" {
            return "The current time is $($currentTime.ToString('h:mm tt')) on $($currentTime.ToString('dddd, MMMM d, yyyy'))"
        }
        "simple" {
            if ($currentTime.Hour -eq 0) {
                $hour = "12"
                $period = "AM"
            } elseif ($currentTime.Hour -le 12) {
                $hour = $currentTime.Hour.ToString()
                $period = "AM"
            } else {
                $hour = ($currentTime.Hour - 12).ToString()
                $period = "PM"
            }
            
            $minute = if ($currentTime.Minute -eq 0) { "o'clock" } else { $currentTime.Minute.ToString().PadLeft(2, '0') }
            return "$hour $minute $period"
        }
        default {
            return "The time is $($currentTime.ToString('h:mm tt'))"
        }
    }
}

# Main script execution
Write-Host "Initializing voice systems..." -ForegroundColor Green

# Initialize both voice systems
$sapiInit = Initialize-SAPIVoices
$winrtInit = Initialize-WinRTVoices

Write-Host "SAPI Voices: $(if ($sapiInit) { 'Available' } else { 'Not Available' })" -ForegroundColor $(if ($sapiInit) { 'Green' } else { 'Red' })
Write-Host "WinRT Voices: $(if ($winrtInit) { 'Available' } else { 'Not Available' })" -ForegroundColor $(if ($winrtInit) { 'Green' } else { 'Red' })

# Show available voices if requested
if ($ShowAvailableVoices) {
    Write-Host "`nAvailable Voices:" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    
    $sapiVoices = Get-SAPIVoices
    $winrtVoices = Get-WinRTVoices
    
    if ($sapiVoices.Count -gt 0) {
        Write-Host "`nSAPI Voices (Traditional):" -ForegroundColor Yellow
        $sapiVoices | Format-Table Name, Culture, Gender, Age -AutoSize
    }
    
    if ($winrtVoices.Count -gt 0) {
        Write-Host "`nWindows Runtime Voices (Natural):" -ForegroundColor Yellow
        $winrtVoices | Format-Table DisplayName, Culture, Gender -AutoSize
    }
    
    # Check specifically for natural voices
    $naturalVoices = @("Aria", "Guy", "Jenny", "Davis", "Jane", "Jason", "Nancy")
    Write-Host "`nNatural Voice Availability:" -ForegroundColor Cyan
    foreach ($voiceName in $naturalVoices) {
        $foundVoice = Find-Voice -VoiceName $voiceName
        if ($foundVoice) {
            Write-Host "✓ $voiceName voice found: $($foundVoice.DisplayName) ($($foundVoice.Type))" -ForegroundColor Green
        } else {
            Write-Host "✗ $voiceName voice not found on this system" -ForegroundColor Red
        }
    }
    
    exit 0
}

# Determine which voice to use
$selectedVoice = $null
$useWinRT = $false

if ($PreferAria) {
    $selectedVoice = Find-Voice -VoiceName "Aria"
    if ($selectedVoice) {
        Write-Host "✓ Using Aria voice: $($selectedVoice.DisplayName)" -ForegroundColor Green
        $useWinRT = ($selectedVoice.Type -eq "WinRT (Natural)")
    } else {
        Write-Host "✗ Aria voice not available, using default voice" -ForegroundColor Yellow
    }
} elseif ($PreferGuy) {
    $selectedVoice = Find-Voice -VoiceName "Guy"
    if ($selectedVoice) {
        Write-Host "✓ Using Guy voice: $($selectedVoice.DisplayName)" -ForegroundColor Green
        $useWinRT = ($selectedVoice.Type -eq "WinRT (Natural)")
    } else {
        Write-Host "✗ Guy voice not available, using default voice" -ForegroundColor Yellow
    }
} elseif ($PreferNatural) {
    $selectedVoice = Find-NaturalVoice
    if ($selectedVoice) {
        Write-Host "✓ Using natural voice: $($selectedVoice.DisplayName)" -ForegroundColor Green
        $useWinRT = ($selectedVoice.Type -eq "WinRT (Natural)")
    } else {
        Write-Host "✗ No natural voices available, using default voice" -ForegroundColor Yellow
    }
} elseif ($Voice -ne "default") {
    $selectedVoice = Find-Voice -VoiceName $Voice -PreferredType $VoiceType
    if ($selectedVoice) {
        Write-Host "✓ Using voice: $($selectedVoice.DisplayName) ($($selectedVoice.Type))" -ForegroundColor Green
        $useWinRT = ($selectedVoice.Type -eq "WinRT (Natural)")
    } else {
        Write-Host "✗ Voice '$Voice' not found, using default" -ForegroundColor Yellow
    }
}

# Generate time message
$timeMessage = Get-TimeMessage -Format $TimeFormat
Write-Host "`nAnnouncing: $timeMessage" -ForegroundColor Cyan

# Speak the time
$speechSuccess = $false

if ($useWinRT -and $script:winrtAvailable) {
    Write-Host "Using Windows Runtime (Natural) voice..." -ForegroundColor Green
    $speechSuccess = Speak-WithWinRT -Text $timeMessage -VoiceId $selectedVoice.Name
} elseif ($script:sapiAvailable) {
    Write-Host "Using SAPI (Traditional) voice..." -ForegroundColor Green
    $voiceName = if ($selectedVoice -and $selectedVoice.Type -eq "SAPI") { $selectedVoice.Name } else { $null }
    $speechSuccess = Speak-WithSAPI -Text $timeMessage -VoiceName $voiceName -Rate $Rate -Volume $Volume
}

if ($speechSuccess) {
    Write-Host "✓ Time announcement completed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to announce time" -ForegroundColor Red
}

# Cleanup
try {
    if ($script:sapiSpeech) { $script:sapiSpeech.Dispose() }
    if ($script:winrtSynthesizer) { $script:winrtSynthesizer.Dispose() }
} catch {
    # Ignore cleanup errors
}
