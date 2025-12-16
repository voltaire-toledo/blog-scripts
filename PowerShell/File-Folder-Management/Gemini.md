Here is a prompt optimized for a Gemini CLI session. It is structured as a clear, direct set of instructions for an expert assistant.

---

Create a single, complete PowerShell script named `Rename-jpgOnDateTaken.ps1`.

### **Primary Goal**
The script must rename JPG files in a specified directory based on their metadata.

### **Detailed Requirements**

**1. Naming Convention:**
*   The final filename format must be: `yyyy-MM-dd_####x####_###.jpg`.
    *   `yyyy-MM-dd`: The date derived from file metadata.
    *   `####x####`: The image's pixel dimensions (`width` x `height`).
    *   `###`: A three-digit, zero-padded index, starting from `001`.

**2. Date Logic (Fallback Order):**
*   The script must determine the date using the following priority:
    1.  First, try the EXIF **"Date Taken"** property.
    2.  If unavailable, fall back to the **"Date Acquired"** property.
    3.  If both are unavailable, use the file's **"Date Modified"** timestamp.

**3. Uniqueness & Collision Handling:**
*   Before renaming, check if a file with the target name already exists.
*   If the name is taken, increment the three-digit index (`001`, `002`, `003`, etc.) until a unique name is found.

**4. Idempotency (Ignore Already Renamed Files):**
*   The script must not process or re-rename files that **already** match the final `yyyy-MM-dd_####x####_###.jpg` pattern.
*   Include a regex check to perform this validation and use `Write-Verbose` to state which files are being skipped.

**5. PowerShell Implementation and Best Practices:**
*   The script must accept a `-DirectoryPath` parameter. If the parameter is not provided, it must default to the current directory.
*   Use the `Shell.Application` COM object to reliably access extended metadata properties, as `Get-ItemProperty` is insufficient for this task.
*   The script must dynamically find the integer indices for the "Date Taken", "Date Acquired", "Date Modified", "Width", and "Height" properties.
*   Implement `[CmdletBinding(SupportsShouldProcess=$true)]` to ensure native support for `-WhatIf`, `-Confirm`, and `-Force`.
*   Include a complete, comment-based help block at the top of the script, detailing the `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and providing at least two `.EXAMPLE` use cases.
*   Handle potential errors gracefully, such as for date parsing or invalid directory paths.
