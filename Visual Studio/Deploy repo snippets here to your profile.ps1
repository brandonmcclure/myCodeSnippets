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
    .INPUTS
       None
    .OUTPUTS
       None
    #>
[CmdletBinding(SupportsShouldProcess=$true)] 
param([string]$DeployForUser = $null,$VSVersion = '2017')
$origLocation = Get-Location
$WhatIfPreference = $true
$rootPath = "$env:USERPROFILE\Documents\"#\Visual Basic\My Code Snippets

if([string]::IsNullOrEmpty($DeployForUser)){
    $userPath = "$env:USERPROFILE\Documents\"#Visual Studio 2015\Code Snippets\SQL\My Code Snippets"
}
else{
    try{
        gci "C:\users\$DeployForUser" -ErrorAction Stop | Out-Null
    }
    catch{
        throw "You do not have access, or the directory does not exist: C:\users\$DeployForUser"
        return
    }

    $userPath = "C:\users\$DeployForUser\Documents"#\Visual Studio 2015\Code Snippets\SQL\My Code Snippets"
}

switch ($VSVersion){
    "2017" {$VSFolderPart = "Visual Studio 2017\Code Snippets";break;}
}

if([string]::IsNullOrEmpty($VSFolderPart)){
    Write-Log "Unknown VSVersion" Error -ErrorAction Stop

}

Write-Log "$PSCommandPath started at: [$([DateTime]::Now)]"

try{
Set-Location (Split-Path $PSCommandPath -Parent)
$folders = Get-ChildItem | where {$_ -is [System.IO.DirectoryInfo]}
$SnippetFolderCount = $folders | measure-Object | select -ExpandProperty Count
if ($SnippetFolderCount -eq 0){
    Write-Log "No sub folders" Error -ErrorAction Stop
}

foreach ($f in $folders ){
    try{set-location $($f.FullName)}catch{Write-Log "Could not change directory to $($f.FullName)" Warning; continue;}
    $deployedFolder = "$userPath\$VSFolderPart\$($f.Name)\My Code Snippets"
    Write-Log "Deploying snippets from $($f.fullName) to $deployedFolder"
if (!(Test-Path (Split-Path $deployedFolder -parent))){New-Item -ItemType Directory -Force -Path $deployedFolder -Verbose:([bool]$VerbosePreference -eq 'Continue') -WhatIf:([bool]$WhatIfPreference.IsPresent)}

Get-ChildItem -Recurse | Where {$_.Extension -eq ".snippet"} |ForEach-Object { 
        # Save full name to avoid issues later
        $Source = $_.FullName

        # Construct destination filename using relative path and destination root
        $Destination = '{0}\{1}' -f $deployedFolder,  (Resolve-Path -Relative -Path:$Source).TrimStart('.\')

        # If new destination doesn't exist, create it
        If(-Not (Test-Path ($DestDir = Split-Path -Parent -Path:$Destination))) { 
            New-Item -Type:Directory -Path:$DestDir -Force -Verbose:([bool]$VerbosePreference -eq 'Continue') -WhatIf:([bool]$WhatIfPreference.IsPresent) 
        }

        # Copy old item to new destination
        Copy-Item -Path:$Source -Destination:$Destination -Verbose:([bool]$VerbosePreference -eq 'Continue') -WhatIf:([bool]$WhatIfPreference.IsPresent)
}
}
}
catch{throw}
finally{
Set-Location $origLocation
}