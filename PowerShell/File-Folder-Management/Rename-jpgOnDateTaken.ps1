<#
.SYNOPSIS
    Renames JPG files based on their "Date Taken", "Date Acquired", or "Date Modified" properties and image dimensions.

.DESCRIPTION
    This script renames JPG files in a specified directory to a standardized format: "yyyy-MM-dd_w####_h####_###.jpg".
    The date is determined by the first available property in the following order: "Date Taken", "Date Acquired", "Date Modified".
    The width and height are from the image dimensions.
    An index is appended to handle files with the same date and dimensions.

    The script supports -WhatIf to show what would be renamed without actually performing the rename.
    It will also ignore files that already follow the 'yyyy-MM-dd_w####_h####_###.jpg' pattern.

.PARAMETER DirectoryPath
    The path to the directory containing the JPG files to be renamed. Defaults to the current directory.

.PARAMETER IndexStart
    The starting number for the index in the filename. Defaults to 1.

.EXAMPLE
    PS C:\> .\Rename-jpgOnDateTaken.ps1 -WhatIf
    Description:
    This command previews the renaming of JPG files in the current directory.

.EXAMPLE
    PS C:\> .\Rename-jpgOnDateTaken.ps1 -DirectoryPath "C:\Photos" -Force
    Description:
    This command renames all JPG files in "C:\Photos" according to the specified format.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$DirectoryPath = (Get-Location).Path,

    [Parameter(Mandatory=$false)]
    [int]$IndexStart = 1
)

$shell = New-Object -COMObject Shell.Application
$folder = $shell.Namespace($DirectoryPath)

if (-not $folder) {
    Write-Error "Could not access directory: $DirectoryPath."
    exit 1
}

# Define the regex pattern for already renamed files
# Matches: yyyy-MM-dd_w<digits>_h<digits>_<3 digits>.jpg
$renamedPattern = "^\d{4}-\d{2}-\d{2}_w\d+_h\d+_\d{3}\.jpg$"

# Find property indices
$propIndices = @{}
$propertiesToFind = @("Date taken", "Date acquired", "Date modified", "Width", "Height")
for ($i = 0; $i -lt 500; $i++) {
    $header = $folder.GetDetailsOf($null, $i)
    if ($header -in $propertiesToFind) {
        $propIndices[$header] = $i
    }
    if ($propIndices.Count -eq $propertiesToFind.Count) { break }
}

if (-not ($propIndices.ContainsKey("Width") -and $propIndices.ContainsKey("Height"))) {
    Write-Warning "Could not find all required properties (Width, Height)."
    exit 1
}

$files = Get-ChildItem -Path $DirectoryPath -Filter "*.jpg"
foreach ($file in $files) {
    # Skip files that already match the renamed pattern
    if ($file.Name -match $renamedPattern) {
        Write-Verbose "Skipping $($file.Name) as it already matches the target naming pattern."
        continue
    }

    $shellFile = $folder.ParseName($file.Name)

    $dateStr = $null
    $dateSource = $null

    if ($propIndices.ContainsKey("Date taken")) {
        $dateStr = $folder.GetDetailsOf($shellFile, $propIndices["Date taken"])
        if ($dateStr) { $dateSource = "Date taken" }
    }
    
    if (-not $dateStr -and $propIndices.ContainsKey("Date acquired")) {
        $dateStr = $folder.GetDetailsOf($shellFile, $propIndices["Date acquired"])
        if ($dateStr) { $dateSource = "Date acquired" }
    }

    if (-not $dateStr -and $propIndices.ContainsKey("Date modified")) {
        $dateStr = $folder.GetDetailsOf($shellFile, $propIndices["Date modified"])
        if ($dateStr) { $dateSource = "Date modified" }
    }
    
    $widthStr = $folder.GetDetailsOf($shellFile, $propIndices["Width"])
    $heightStr = $folder.GetDetailsOf($shellFile, $propIndices["Height"])

    if ($dateStr -and $widthStr -and $heightStr) {
        try {
            $cleanedDateStr = $dateStr.Trim() -replace '[^\w\s\d:/\\]'
            $dateValue = [datetime]::Parse($cleanedDateStr, [System.Globalization.CultureInfo]::CurrentCulture)
            $width = $widthStr -replace '\D'
            $height = $heightStr -replace '\D'
            
            $index = $IndexStart
            do {
                $newName = "{0:yyyy-MM-dd}_w{1}_h{2}_{3:D3}.jpg" -f $dateValue, $width, $height, $index
                $newFilePath = Join-Path -Path $DirectoryPath -ChildPath $newName
                $index++
            } while (Test-Path -Path $newFilePath)

            if ($pscmdlet.ShouldProcess($file.Name, "Rename to $newName (using $dateSource)")) {
                Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
            }
        }
        catch {
            Write-Warning "Could not process file $($file.Name). Error: $($_.Exception.Message)"
        }
    }
}