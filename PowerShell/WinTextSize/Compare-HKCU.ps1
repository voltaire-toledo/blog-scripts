# Define temporary file paths
$tempFile1 = "$env:TEMP\hkcu_snapshot1.reg"
$tempFile2 = "$env:TEMP\hkcu_snapshot2.reg"

function Parse-RegFile {
    param ([string]$FilePath)
    
    Write-Host "Parsing $FilePath..." -ForegroundColor Gray
    
    $results = @()
    $currentKey = ""
    
    # Read file efficiently
    foreach ($line in Get-Content $FilePath) {
        $line = $line.Trim()
        
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        
        # Check if line is a key path (e.g., [HKEY_CURRENT_USER\...])
        if ($line.StartsWith('[') -and $line.EndsWith(']')) {
            $currentKey = $line
        }
        else {
            # It's a value or data line. Add to results with context.
            # We construct a custom string for comparison that includes the key
            # so Compare-Object treats the Key+Value combo as the unique item.
            $results += [PSCustomObject]@{
                Key   = $currentKey
                Value = $line
            }
        }
    }
    return $results
}

# 1. Snapshot 1
Write-Host "Taking initial snapshot of HKEY_CURRENT_USER..." -ForegroundColor Cyan
reg.exe export HKCU $tempFile1 /y

# 2. Wait for user changes
Write-Host "`nSnapshot 1 complete." -ForegroundColor Green
Read-Host "Make your registry changes now, then press [Enter] to continue..."

# 3. Snapshot 2
Write-Host "`nTaking second snapshot of HKEY_CURRENT_USER..." -ForegroundColor Cyan
reg.exe export HKCU $tempFile2 /y

# 4. Compare
Write-Host "Reading and analyzing snapshots (this may take a moment)..." -ForegroundColor Cyan

try {
    $data1 = Parse-RegFile $tempFile1
    $data2 = Parse-RegFile $tempFile2

    Write-Host "Comparing data..." -ForegroundColor Cyan
    
    # Compare the objects based on both Key and Value properties
    $diff = Compare-Object -ReferenceObject $data1 -DifferenceObject $data2 -Property Key, Value

    if ($diff) {
        Write-Host "`nDifferences found:" -ForegroundColor Yellow
        
        # Group by Key for cleaner output
        $diff | Group-Object Key | ForEach-Object {
            Write-Host "`nKey: $($_.Name)" -ForegroundColor Magenta
            foreach ($change in $_.Group) {
                if ($change.SideIndicator -eq '<=') {
                    # Removed/Old Value
                    Write-Host "  [-] $($change.Value)" -ForegroundColor Red
                }
                elseif ($change.SideIndicator -eq '=>') {
                    # Added/New Value
                    Write-Host "  [+] $($change.Value)" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "`nNo differences found." -ForegroundColor Gray
    }
}
catch {
    Write-Error "An error occurred during comparison: $_"
}

# 5. Cleanup
Write-Host "`nCleaning up temporary files..." -ForegroundColor DarkGray
Remove-Item $tempFile1 -ErrorAction SilentlyContinue
Remove-Item $tempFile2 -ErrorAction SilentlyContinue

Write-Host "Done." -ForegroundColor Green