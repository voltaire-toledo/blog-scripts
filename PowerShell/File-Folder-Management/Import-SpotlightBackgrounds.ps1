# --- Script Configuration ---
$source = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
$destination = $PSScriptRoot

# --- Pre-run Checks ---
# Explicitly load the .NET assembly needed for image processing. This often solves context menu issues.
try {
    Add-Type -AssemblyName System.Drawing
}
catch {
    Write-Host "FATAL: Could not load the required System.Drawing assembly." -ForegroundColor Red
    Write-Host $_.Exception.Message
    pause
    exit
}

# Ensure the source directory exists
if (-not (Test-Path -Path $source)) {
    Write-Host "ERROR: Windows Spotlight assets folder not found at the expected location." -ForegroundColor Red
    pause
    exit
}


# --- Main Logic ---
$images = Get-ChildItem -Path $source
foreach ($img in $images) {
    # A try/catch block will find the error instead of crashing the script silently.
    try {
        $temp = Join-Path $env:TEMP ($img.Name + ".jpg")
        Copy-Item $img.FullName $temp -Force -ErrorAction Stop

        # Get image dimensions
        $imageObject = [System.Drawing.Image]::FromFile($temp)
        $isLandscape = $imageObject.Width -gt $imageObject.Height
        
        # IMPORTANT: Release the lock on the temp file
        $imageObject.Dispose()

        if ($isLandscape) {
            $destFile = Join-Path $destination ($img.Name + ".jpg")
            # This is more efficient: move the temp file instead of copying the source a second time.
            Move-Item -Path $temp -Destination $destFile -Force
            Write-Host "Copied: $destFile"
        }
        else {
            # If it's not a landscape image, just delete the temp file.
            Remove-Item $temp -Force
        }
    }
    catch {
        Write-Host "An error occurred while processing file: $($img.Name)" -ForegroundColor Red
        # This will print the actual error message to the screen.
        Write-Host "DETAILS: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`nScript finished. Press Enter to exit."
pause