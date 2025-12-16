This prompt is structured for Anthropic's Claude model, using XML tags to delineate roles, instructions, and examples, as recommended in its documentation.

---

You are an expert PowerShell developer. Your task is to write a single, complete, and robust PowerShell script based on the detailed requirements provided below. The script should be production-quality, following all modern PowerShell best practices.

<script_requirements>
    <purpose>
        The script, to be named `Rename-jpgOnDateTaken.ps1`, will batch-rename JPG files in a directory. The new name will be based on the image's metadata to create a standardized, chronological, and descriptive filename.
    </purpose>

    <naming_convention>
        The target filename format is `yyyy-MM-dd_####x####_###.jpg`.
        - The first element is the date.
        - The second element is the image's pixel dimensions, with width and height separated by a literal 'x'.
        - The third element is a 3-digit, zero-padded index to ensure uniqueness.
    </naming_convention>

    <date_logic>
        The date for the filename must be determined using a fallback priority system:
        1.  Attempt to use the EXIF "Date Taken" value first.
        2.  If "Date Taken" is null or empty, use the "Date Acquired" value.
        3.  If both are null or empty, use the file's "Date Modified" timestamp.
    </date_logic>
    
    <uniqueness_logic>
        The script must guarantee unique filenames. If it generates a name that already exists in the target directory, it must increment the 3-digit index (e.g., from 001 to 002) and re-check, repeating this process until an unused filename is found.
    </uniqueness_logic>
    
    <idempotency>
        The script must be idempotent, meaning it will not re-process files it has already successfully renamed. It must check if a file's name already matches the target format (`yyyy-MM-dd_####x####_###.jpg`) at the beginning of its processing loop. If it matches, the script should skip that file entirely.
    </idempotency>
    
    <powershell_specifics>
        - The script must be a standalone `.ps1` file.
        - It must include `[CmdletBinding(SupportsShouldProcess=$true)]` to enable `-WhatIf`, `-Confirm`, and `-Force` functionality.
        - It must define a `-DirectoryPath` parameter that defaults to the current location if not specified.
        - To access the required EXIF and file metadata, it must use the `Shell.Application` COM object and dynamically resolve the property indices for "Date Taken", "Date Acquired", "Date Modified", "Width", and "Height".
        - The script must begin with a full comment-based help block, including `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE` sections.
    </powershell_specifics>
</script_requirements>

<examples>
    <example_1 description="A dry-run to preview changes in the current folder.">
        PS C:\> .\Rename-jpgOnDateTaken.ps1 -WhatIf
    </example_1>
    
    <example_2 description="Executing the rename on a specific folder, overriding any confirmation prompts.">
        PS C:\> .\Rename-jpgOnDateTaken.ps1 -DirectoryPath "D:\Photos\2024" -Force
    </example_2>
</examples>

<output_format>
    Please provide only the complete PowerShell script content in a single code block. Do not add any extra explanations outside of the script's own comment-based help.
</output_format>
