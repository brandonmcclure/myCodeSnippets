<#
    .Synopsis
      Copies the SQL code snippets to your user profile on this machine. 
    .DESCRIPTION
      This will overwrite any existing snippets with the same name that you have. 
    .PARAMETER DeployForUser
        Will attempt to deploy to this user's profile directory if not null. IE use this to populate for your _adm accounts without needing to run the script as that user. You would need to run this script as an administrator
    .EXAMPLE
        Run with -Whatif to see what the script will do. 

        & '.\Deploy repo snippets here to your profile.ps1' -WhatIf

    .EXAMPLE
        Run with the -Verbose switch to get more output from the script.
        & '.\Deploy repo snippets here to your profile.ps1' -Verbose

    .EXAMPLE
        Only install for SSMS 18.x
        & '.\Deploy repo snippets here to your profile.ps1' -SSMSVersions "18"
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string]$DeployForUser = $null,
[string[]][ValidateSet("17","18")]$SSMSVersions = @("18","17"))
$origLocation = Get-Location

foreach ($SSMSVersion in $SSMSVersions){
if ($SSMSVersion -eq "18"){
    $SubPath = "Documents\SQL Server Management Studio\Code Snippets\SQL\My Code Snippets"
}
if ($SSMSVersion -eq "17"){
    $SubPath = "Documents\Visual Studio 2015\Code Snippets\SQL\My Code Snippets"
}

if([string]::IsNullOrEmpty($SubPath)){
    Write-Log "Could not set the path to install the snippets at" Error -ErrorAction Stop
}

if([string]::IsNullOrEmpty($DeployForUser)){
    $deployedFolder = "$env:USERPROFILE\$SubPath"
}
else{
    try{
        gci "C:\users\$DeployForUser" -ErrorAction Stop | Out-Null
    }
    catch{
        throw "You do not have access, or the directory does not exist: C:\users\$DeployForUser"
        return
    }

    $deployedFolder = "C:\users\$DeployForUser\$SubPath"
}
Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]"

try{
Set-Location (Split-Path $PSCommandPath -Parent)
if (!(Test-Path (Split-Path $deployedFolder -parent))){New-Item -ItemType Directory -Force -Path $deployedFolder -Verbose:([bool]$VerbosePreference -eq 'Continue') -WhatIf:([bool]$WhatIfPreference.IsPresent)}

Get-ChildItem -Path "$(SPlit-Path $PSCommandPath -Parent)\*" -Recurse | Where {$_.Extension -eq ".snippet"} |ForEach-Object { 
        # Save full name to avoid issues later
        $Source = $_.FullName

        # Construct destination filename using relative path and destination root
        $Destination = '{0}\{1}' -f $deployedFolder, (Resolve-Path -Relative -Path:$Source).TrimStart('.\')

        # If new destination doesn't exist, create it
        If(-Not (Test-Path ($DestDir = Split-Path -Parent -Path:$Destination))) { 
            New-Item -Type:Directory -Path:$DestDir -Force -Verbose:([bool]$VerbosePreference -eq 'Continue') -WhatIf:([bool]$WhatIfPreference.IsPresent) 
        }

        # Copy old item to new destination
        Copy-Item -Path:$Source -Destination:$Destination -Verbose:([bool]$VerbosePreference -eq 'Continue') -WhatIf:([bool]$WhatIfPreference.IsPresent)
}
}
catch{throw}
finally{
Set-Location $origLocation
}
}