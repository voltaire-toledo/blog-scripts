<#
.SYNOPSIS
    Retrieves the "Date Taken" metadata property from all JPG files in a specified directory.

.DESCRIPTION
    This script inspects all files with a .jpg extension within a given directory. It uses the Shell.Application COM object to access extended file properties and extracts the "Date Taken" value from the EXIF metadata.

    The script will output a list of JPG files and their corresponding "Date Taken" value. It will also provide a summary of how many JPG files were found and how many of them had the "Date Taken" property.

.PARAMETER DirectoryPath
    The path to the directory containing the JPG files to be analyzed. If not provided, the script will use the current directory.

.EXAMPLE
    PS C:\> .\Get-JPGDateTaken.ps1
    Description:
    This command will analyze the JPG files in the current directory and display their "Date Taken" property.

.EXAMPLE
    PS C:\> .\Get-JPGDateTaken.ps1 -DirectoryPath "C:\Users\User\Pictures"
    Description:
    This command will analyze the JPG files in the "C:\Users\User\Pictures" directory and display their "Date Taken" property.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]$DirectoryPath = (Get-Location).Path
)

# Initialize the Shell.Application COM object to access extended file properties.
$shell = New-Object -COMObject Shell.Application
$folder = $shell.Namespace($DirectoryPath)

if (-not $folder) {
    Write-Error "Could not access directory: $DirectoryPath. Please ensure the path is valid."
    exit 1
}

# The "Date Taken" property is not available through a fixed property name with Get-ItemProperty.
# We need to find the index of the "Date Taken" property by iterating through the available properties.
# The index can vary between systems, so we cannot hardcode it.
$dateTakenIndex = -1
# We check up to 300 properties, which is a safe upper limit for finding "Date taken".
for ($i = 0; $i -lt 300; $i++) {
    $header = $folder.GetDetailsOf($null, $i)
    if ($header -eq "Date taken") {
        $dateTakenIndex = $i
        break
    }
}

if ($dateTakenIndex -ne -1) {
    Write-Verbose "The 'Date Taken' property was found at index $dateTakenIndex."
    Write-Host "Analyzing JPG files in: $DirectoryPath"

    $countWithDateTaken = 0
    $countTotalJpg = 0

    # Iterate through all items in the folder.
    $folder.Items() | ForEach-Object {
        $file = $_
        # Check if the item is a JPG file.
        if ($file.Name -like "*.jpg") {
            $countTotalJpg++
            $dateTaken = $folder.GetDetailsOf($file, $dateTakenIndex)
            # If the "Date Taken" property has a value, print it.
            if ($dateTaken) {
                Write-Host "$($file.Name): $dateTaken"
                $countWithDateTaken++
            }
        }
    }

    # Provide a summary of the analysis.
    Write-Host "--- Summary ---"
    Write-Host "Total JPG files found: $countTotalJpg"
    Write-Host "Files with 'Date Taken' property: $countWithDateTaken"
} else {
    Write-Warning "The 'Date taken' property could not be found for files in '$DirectoryPath'. This may indicate that the property is not available on this system or in this folder."
}