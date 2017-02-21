<#

File:      KeepItUpdated.ps1
Version:   1.1, updated 2017-01-11
Author:    Victor Dahlberg, Office IT-Partner
Blog:      http://deployman.wordpress.com
Purpose:   The script itself will try to download files using Invoke-Webrequest, it's main objective is to
           automate the task of updating the applications in your MDT DeploymentShare.
Usage:   - Run Powershell Script with the following parameters:
           ./KeepItUpdated.ps1
Warning:   This script is provided "AS IS" with no warranties and is not supported by the author.

#>

# -----------------------------------------------------------------------------------------------------------------------------------------------------------------
# CreateFolders: Function to create download folder
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------

Function CreateFolders {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$CurrPath
    )

    Try {

        # Create the download path if it doesn't already exist
        If (!(Test-Path $CurrPath)) {
            New-Item "$CurrPath" -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
    }
         
    Catch {
        Write-Warning "Failed to create download folder with error message: $($_.Exception.Message)"
        Break
    }
}

# -----------------------------------------------------------------------------------------------------------------------------------------------------------------
# DownloadFiles: Function to download files
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------

Function DownloadFiles {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$DownloadUrl,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$CurrFile
    )

    Try {

        # Download the files
        $ProgressPreference = "SilentlyContinue"
        Write-Progress -Activity "Downloading $DispName" -Status "Please wait..."
        Invoke-WebRequest $DownloadUrl -OutFile $CurrFile -ErrorAction Stop | Out-Null
        Write-Host "[?] File downloaded successfully" -ForegroundColor Cyan
    }

    Catch {
        Write-Warning "Failed to download application with error message: $($_.Exception.Message)"
    }
}

# -----------------------------------------------------------------------------------------------------------------------------------------------------------------
# CompareFiles: Function to compare file versions and replace files
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------

Function CompareFiles {
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$CurrFile,
        [Parameter(Mandatory=$false)]
        [String]$PrevFile
    )

    Try {

        # Check if there is any file to compare with
        If ($PrevFile | Test-Path -ErrorAction SilentlyContinue) {

            # Check for matching hash
            If ((Get-FileHash $CurrFile).Hash -eq (Get-FileHash $PrevFile).Hash) {
                Write-Host "[?] File hash match, keeping existing file" -ForegroundColor Cyan
            }
     
            # If hash does not match
            Else {

                # Loop until file has been successfully removed
                Do {
                    Remove-Item "$PrevFile" -Force -Recurse -ErrorAction Stop
                }
            
                # Verify that the old file has been removed before trying to copy the new one
                While (!(Test-Path -Path "$PrevFile"))
                Copy-Item "$CurrFile" -Destination "$PrevPath" -Force -ErrorAction Stop
                Write-Host "[?] File hash do not match, files were replaced" -ForegroundColor Cyan
            }
        }
    }

    Catch {
        Write-Warning "Failed to replace application with error message: $($_.Exception.Message)"
        Break
    }
}

# -----------------------------------------------------------------------------------------------------------------------------------------------------------------
# Begin processing the XML-data and start up the main functions of the script
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------

$LogPath = Join-Path -Path $PSScriptRoot -ChildPath "$($MyInvocation.MyCommand.Name)_$(Get-Date -Format 'yyyy-MM-dd_HH_mm_ss').log"

Start-Transcript -Path "$LogPath" -Force | Out-Null

# Import XML-data
Try {
    [xml]$DownloadSettings = Get-Content $(Join-Path -Path $PSScriptRoot -ChildPath "DownloadSettings.xml")
}

Catch {
    Write-Warning "Failed to read XML-fil with error message: $($_.Exception.Message)"
    Break
}

# Reset progress bar counter
$Counter = 0

# Process XML-data and set data as variables
Foreach ($Application in $DownloadSettings.xml.Application) {

    $DownloadUrl = $Application.DownloadUrl
    $ApplicationName = $Application.ApplicationName
    $Filename = $Application.Filename
    $Keyword = $Application.Keyword

    Try {

        # Use these settings if link and keyword is found but filename is not set
        If ($DownloadUrl -and $Keyword -and !$Filename) {   
            $DownloadUrl = ((Invoke-WebRequest $DownloadUrl).Links | Where {$_.href -like "*http*$Keyword*"}).href
        }

        # Use these settings if link, keyword and filename are all found
        ElseIf ($DownloadUrl -and $Keyword -and $Filename) {
            $DownloadUrl = ((Invoke-WebRequest $DownloadUrl).Links | Where {$_.href -like "*http*$Keyword" -or $_.innerText -like "$Keyword"}).href
        }
    }

    Catch {
        Write-Warning "Failed to query $DownloadUrl with error message: $($_.Exception.Message)"
    }

    # Gather final variables
    $Filename = $DownloadUrl.Split('/')[-1].Split('?')[0] -Replace "%20","_"
    $DispName = $ApplicationName -Replace "Install - ",""

    $CurrPath = Join-Path -Path $PSScriptRoot -ChildPath "Downloads" | Join-Path -ChildPath $ApplicationName | Join-Path -ChildPath "Source"
    $PrevPath = Join-Path -Path $PSScriptRoot -ChildPath "Applications" | Join-Path -ChildPath $ApplicationName | Join-Path -ChildPath "Source"
    
    $CurrFile = Join-Path -Path $CurrPath -ChildPath "$Filename" -ErrorAction SilentlyContinue
    $PrevFile = Join-Path -Path $PrevPath -ChildPath "*" -Resolve -ErrorAction SilentlyContinue

    # Output useful information to the logfile in case of troubleshooting
    Write-Host ""
    Write-Host "$DispName" -ForegroundColor White
    Write-Host "---------------------------------------------------------------------"
    Write-Information "DeploymentShare: $PrevPath"
    Write-Information "DownloadPath...: $CurrPath"
    Write-Information "DownloadURL....: $DownloadUrl"
    Write-Information "Filename.......: $Filename"
    Write-Information "Keyword........: $Keyword"

    # Progress bar
    $Counter++
    Write-Progress -Activity "Processing $($DispName)" -Status "Processing $($Counter) of $($DownloadSettings.xml.Application.Count) applications" -PercentComplete (($Counter / $DownloadSettings.xml.Application.Count) * 100)
    Start-Sleep -Milliseconds 200

    CreateFolders -CurrPath $CurrPath
    DownloadFiles -DownloadUrl $DownloadUrl -CurrFile $CurrFile
    CompareFiles -CurrFile $CurrFile -PrevFile $PrevFile
}

Write-Host
Stop-Transcript
