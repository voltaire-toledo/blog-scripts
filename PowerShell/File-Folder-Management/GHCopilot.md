This document follows a spec-driven format, suitable for GitHub Copilot or for providing a formal specification to a development team.

---

# **Specification: `Rename-jpgOnDateTaken.ps1`**

## 1. Overview

This document specifies the requirements for a PowerShell script, `Rename-jpgOnDateTaken.ps1`. The script's purpose is to batch-rename JPG image files in a specified directory based on their metadata, creating a standardized and chronological naming convention.

## 2. Functional Requirements

| ID    | Requirement                                                                                                                                                                             |
|-------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-1  | The script **SHALL** rename files with a `.jpg` extension located in the directory specified by the `DirectoryPath` parameter.                                                              |
| FR-2  | The new filename format **SHALL** be `yyyy-MM-dd_####x####_###.jpg`, where `####x####` represents the image's width and height.                                                               |
| FR-3  | The date component (`yyyy-MM-dd`) **SHALL** be determined by the first available property in the following order of precedence: (1) "Date Taken", (2) "Date Acquired", (3) "Date Modified". |
| FR-4  | The index component (`###`) **SHALL** be a three-digit, zero-padded integer that starts at `001`.                                                                                           |
| FR-5  | The script **SHALL** handle filename collisions. If a generated filename already exists, the index component **SHALL** be incremented until a unique filename is found.                     |
| FR-6  | The script **SHALL** be idempotent. It **MUST NOT** process any file whose name already conforms to the pattern defined in `FR-2`.                                                        |

## 3. Technical Specifications

| ID    | Specification                                                                                                                               |
|-------|---------------------------------------------------------------------------------------------------------------------------------------------|
| TS-1  | The script **MUST** be implemented in PowerShell and saved as `Rename-jpgOnDateTaken.ps1`.                                                      |
| TS-2  | The script **MUST** define a `DirectoryPath` parameter. If this parameter is not supplied, its value **MUST** default to the current directory. |
| TS-3  | The script **MUST** implement `[CmdletBinding(SupportsShouldProcess=$true)]` to support `-WhatIf`, `-Confirm`, and `-Force` common parameters.   |
| TS-4  | The script **MUST** use the `Shell.Application` COM object to retrieve the "Date Taken", "Date Acquired", "Width", and "Height" metadata.    |
| TS-5  | The script **MUST** dynamically query the system to find the correct property indices for the required metadata fields.                       |

## 4. Non-Functional Requirements

| ID    | Requirement                                                                                             |
|-------|---------------------------------------------------------------------------------------------------------|
| NFR-1 | The script **MUST** include a comment-based help block at the beginning, containing a synopsis, description, parameter explanation, and examples. |
| NFR-2 | The script **SHOULD** handle errors gracefully (e.g., date-parsing errors, invalid directories) and report them to the user as warnings. |
| NFR-3 | Verbose output **SHOULD** be used to indicate when a file is skipped because it already conforms to the target naming pattern. |

## 5. Examples

### Example 1: Preview Renames (Dry Run)
```powershell
.\Rename-jpgOnDateTaken.ps1 -WhatIf -Verbose
```

### Example 2: Execute Rename on a Specific Folder
```powershell
.\Rename-jpgOnDateTaken.ps1 -DirectoryPath "C:\Users\John\Pictures\Vacation" -Force
```
