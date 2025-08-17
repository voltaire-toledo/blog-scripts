
#Requires -Module Az.Accounts
#Requires -Module Az.Resources

# Function to get the current user's object ID
function Get-CurrentUserObjectId {
    try {
        $userJson = az ad signed-in-user show --query '{id:id}' -o json 2>$null
        if ($LASTEXITCODE -ne 0 -or $null -eq $userJson) {
            throw "Failed to get signed-in user from Azure CLI. Please ensure you are logged in."
        }
        $userId = ($userJson | ConvertFrom-Json).id
        if ($null -eq $userId) {
            throw "Could not parse user object ID from Azure CLI output."
        }
        return $userId
    }
    catch {
        Write-Error "Error getting user object ID: $_"
        throw
    }
}

# Function to list eligible role assignments
function Get-EligibleRoleAssignments {
    param (
        [string]$principalId
    )
    try {
        $uri = "https://management.azure.com/providers/Microsoft.Authorization/roleEligibilityScheduleInstances?`$filter=principalId eq '$principalId'&api-version=2020-10-01"
        $token = az account get-access-token --resource "https://management.azure.com/" --query accessToken -o tsv
        if ($LASTEXITCODE -ne 0 -or $null -eq $token) {
            throw "Failed to retrieve access token from Azure CLI."
        }
        $response = Invoke-RestMethod -Uri $uri -Method 'GET' -Headers @{
            "Authorization" = "Bearer $token"
            "Content-Type"  = "application/json"
        }
        return $response.value
    }
    catch {
        Write-Error "Error getting eligible role assignments: $_"
        throw
    }
}

# Function to list active role assignments
function Get-ActiveRoleAssignments {
    param (
        [string]$principalId
    )
    try {
        $uri = "https://management.azure.com/providers/Microsoft.Authorization/roleAssignmentScheduleInstances?`$filter=principalId eq '$principalId'&api-version=2020-10-01"
        $token = az account get-access-token --resource "https://management.azure.com/" --query accessToken -o tsv
        if ($LASTEXITCODE -ne 0 -or $null -eq $token) {
            throw "Failed to retrieve access token from Azure CLI."
        }
        $response = Invoke-RestMethod -Uri $uri -Method 'GET' -Headers @{
            "Authorization" = "Bearer $token"
            "Content-Type"  = "application/json"
        }
        return $response.value
    }
    catch {
        Write-Error "Error getting active role assignments: $_"
        throw
    }
}

# Function to activate a role assignment
function Activate-RoleAssignment {
    param (
        [string]$roleAssignmentId,
        [string]$justification,
        [string]$principalId,
        [string]$roleDefinitionId
    )
    try {
        $uri = "https://management.azure.com$($roleAssignmentId.Replace('/providers/Microsoft.Authorization/roleEligibilityScheduleInstances', '/providers/Microsoft.Authorization/roleAssignmentScheduleRequests'))?api-version=2020-10-01"
        $body = @{
            properties = @{
                principalId      = $principalId
                roleDefinitionId = $roleDefinitionId
                requestType      = "SelfActivate"
                justification    = $justification
                scheduleInfo     = @{
                    startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    expiration    = @{
                        type     = "AfterDuration"
                        duration = "PT8H" # Activate for 8 hours
                    }
                }
            }
        } | ConvertTo-Json -Depth 10

        $token = az account get-access-token --resource "https://management.azure.com/" --query accessToken -o tsv
        if ($LASTEXITCODE -ne 0 -or $null -eq $token) {
            throw "Failed to retrieve access token from Azure CLI."
        }

        Write-Host "Submitting activation request..."
        $response = Invoke-RestMethod -Uri $uri -Method 'PUT' -Headers @{
            "Authorization" = "Bearer $token"
            "Content-Type"  = "application/json"
        } -Body $body

        Write-Host "Activation request submitted. API Response:"
        Write-Host ($response | ConvertTo-Json -Depth 5)

        if ($null -ne $response.properties.status) {
            Write-Host "Activation request status from API: $($response.properties.status)"
        }
    }
    catch {
        Write-Error "Error activating role assignment: $_"
        if ($_.Exception.Response) {
            $errorBody = $_.Exception.Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            Write-Error "Underlying API Error Body: $errorBody"
        }
        throw
    }
}

# Main script
try {
    # This script assumes you are already logged in via Azure CLI in your Cloud Shell environment.

    $principalId = Get-CurrentUserObjectId
    Write-Host "Current user object ID: $principalId"

    $eligibleAssignments = Get-EligibleRoleAssignments -principalId $principalId
    Write-Host "Found $($eligibleAssignments.Count) eligible role assignments."

    # Get active assignments to avoid trying to activate roles that are already active
    $activeAssignments = Get-ActiveRoleAssignments -principalId $principalId
    $activeRoleDefinitionIds = @()
    if ($null -ne $activeAssignments) {
        $activeRoleDefinitionIds = $activeAssignments.properties.roleDefinitionId
    }

    foreach ($assignment in $eligibleAssignments) {
        $roleDefinitionId = $assignment.properties.roleDefinitionId
        $roleName = $roleDefinitionId.Split('/')[-1]

        if ($activeRoleDefinitionIds -contains $roleDefinitionId) {
            Write-Host "Role '$roleName' is already active. Skipping."
        }
        else {
            Write-Host "Activating role: $roleName ($($roleDefinitionId))"
            Activate-RoleAssignment -roleAssignmentId $assignment.id -justification "Activating for client work" -principalId $principalId -roleDefinitionId $roleDefinitionId
        }
    }

    Write-Host "All eligible role assignments have been processed."
}
catch {
    Write-Error "An error occurred: $_"
}
