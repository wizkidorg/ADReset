﻿<#
.SYNOPSIS
Determines if a user's secret questions are set on ADReset. If they aren't, a browser will launch and navigate to ADReset
.DESCRIPTION
Determines if a user's secret questions are set on ADReset. It will query /userstatus.php with the username of the logged on user or the one specified. If they user's secret questions are not set, a browser will launch and navigate to ADReset
.PARAMETER webURI
This is the full link to navigate to ADReset
.PARAMETER username
This is the user the script will check with ADReset to see if their secret questions are configured
.PARAMETER browser
This is the browser that will be used to navigate to ADReset if the user's secret questions are not set

.EXAMPLE
    .\Get-ADResetUserStatus.ps1 -webURI 'adreset.domain.local' -browser  'IE'
.EXAMPLE
    .\Get-ADResetUserStatus.ps1 -webURI 'adreset.domain.local' -browser 'Chrome'
.EXAMPLE
    .\Get-ADResetUserStatus.ps1 -webURI 'adreset.domain.local' -browser 'Firefox'
.EXAMPLE
    .\Get-ADResetUserStatus.ps1 -webURI 'adreset.domain.local' -browser 'IE' -username 'john.smith'
#>

[CmdletBinding()]
param (
    [parameter(Mandatory=$true)]
        [string]$webURI,
    [parameter(Mandatory=$false)]
        [string]$username = $env:USERNAME,
    [parameter(Mandatory=$true)]
        [ValidateSet('IE','Chrome','Firefox')]
        [string]$browser
)

process {
    Write-Host $username
    function StartBrowser() {
        switch ($browser) {
            'IE' {
                $browserPaths = @(
                    'C:\Program Files\Internet Explorer\iexplore.exe',
                    'C:\Program Files (x86)\Internet Explorer\iexplore.exe'
                )
            }

            'Chrome' {
                $browserPaths = @(
                    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
                    'C:\Program Files\Google\Chrome\Application\chrome.exe'
                )
                $browserParameters = '--new-window'
            }
            
            'Firefox' {
                $browserPaths = @(
                    'C:\Program Files (x86)\Mozilla Firefox\firefox.exe',
                    'C:\Program Files\Mozilla Firefox\firefox.exe'
                )
            } 
        }

        if ($browserPaths -ne $null) {
            foreach ($browserPath in $browserPaths) {
                if (Test-Path $browserPath) {
                    if ($browserParameters -ne $null) {
                        Invoke-Expression ("& '" + $browserPath + "' '" + $browserParameters + " " + $webURI + "/account.php?notify=yes'")
                    }
                    else {
                        Invoke-Expression ("& '" + $browserPath + "' '" + $webURI + "/account.php?notify=yes'")
                    }

                    return $true
                }
            }
        }

        return $false
    }

    try {
        Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue
        $uri = $webURI + '/userstatus.php?username=' + [System.Web.HttpUtility]::UrlEncode($username)
        $result = (Invoke-RestMethod -UserAgent "ADReset PowerShell" -Uri $uri -ErrorAction Stop).status
        if ($result -ne $null) {
            if ($result -eq 'incomplete') {
                if (StartBrowser) {
                    return $true
                }
            }
            elseif (($result -eq 'complete') -or ($result -eq 'restricted')) {
                return $true
            }
        }
    }
    catch {
        return $false
    }

    return $false
}