#requires -version 3

<#

.SYNOPSIS
This is a simple Powershell script to download files to your MDT DeploymentShare

.DESCRIPTION
The script itself will try to download the files using Invoke-Webrequest, it's main objective is to
automate the task of updating the applications in your MDT DeploymentShare. 

.EXAMPLE
./KeepItUpdated.ps1

.NOTES
Make sure you run this script with sufficient share permissions.

.DISCLAIMER
This script is provided "AS IS" with no warranties, confers no rights and is not supported by the author.

.AUTHOR
Victor Dahlberg, Office IT-Partner

.DATE
2016-06-02

.LINK
http://deployman.wordpress.com

#>

Clear-Host

##################################################################################################################
# Set variables
##################################################################################################################

$DownloadFolder = "$PSScriptRoot\Downloads"
$ApplicationShare = "$PSScriptRoot\Applications"

$Time = (Get-Date -Format 'yyyy-MM-dd_HH_mm_ss')
$LogPath = "$PSScriptRoot\DownloadLog_$Time.txt"


##################################################################################################################
# Function to create download folder
##################################################################################################################

function CreateDownloadFolder ()
{
  try
  {
    
    if (Test-Path "$FinalDownloadFolder")
    {
      Write-Host "$Step1$Skip" -ForegroundColor Yellow
    }

    else
    {
      New-Item "$FinalDownloadFolder" -ItemType Directory -ErrorAction Stop | Out-Null
      Write-Host "$Step1$Done" -ForegroundColor Green
    }

  }

  catch
  {
    $ErrorMessage = $_.Exception.Message
    Write-Host "$Step1$Fail" -ForegroundColor Red
    Write-Information "Failed to create folder with error message: $ErrorMessage" .
    break
  }

}


##################################################################################################################
# Function to download files
##################################################################################################################

function DownloadFiles ()
{
  try
  {

    Write-Progress -Activity "Downloading $FileName" -Status "Please wait..."
    Invoke-WebRequest $DownloadURL -OutFile $FinalDownloadFolder\$Filename -ErrorAction Stop
    Write-Host "$Step2$Done" -ForegroundColor Green
  }

  catch
  {
    $ErrorMessage = $_.Exception.Message
    Write-Information "Failed to download application with error message: $ErrorMessage" .
    Write-Host "$Step2$Fail" -ForegroundColor Red
    break
  }

}


##################################################################################################################
# Function to compare file versions and replace files
##################################################################################################################

function CompareFilesAndReplace ()
{

  try
  {

    $NewFile = (Get-Item $FinalDownloadFolder\$Filename -ErrorAction SilentlyContinue)
    $OldFile = (Get-Item $FinalApplicationShare\*.* -ErrorAction SilentlyContinue)

    $NewFileVersion = $NewFile.VersionInfo.FileVersion -replace ",","." -replace " ",""
    $OldFileVersion = $OldFile.VersionInfo.FileVersion -replace ",","." -replace " ",""

    if ($OldFile -and $NewFile)
    {

      if ($NewFileVersion -gt $OldFileVersion)
      {
        Write-Host "$Step3$Done" -ForegroundColor Green
        Remove-Item "$OldFile" -Force -ErrorAction Stop
        Copy-Item "$NewFile" -Destination "$FinalApplicationShare" -Force -ErrorAction Stop
        Write-Host "$Step4$Done" -ForegroundColor Green
        Write-Host ""
        Write-Host "INFO: $NewFileVersion > $OldFileVersion" -ForegroundColor Cyan
        Write-Host "INFO: An update was found, files were replaced..." -ForegroundColor Cyan
      }
      
      elseif ($NewFileVersion -eq "" -and $OldFileVersion -eq "")
      {
        Write-Host "$Step3$Done" -ForegroundColor Green
        Remove-Item "$OldFile" -Force -ErrorAction Stop
        Copy-Item "$NewFile" -Destination "$FinalApplicationShare" -Force -ErrorAction Stop
        Write-Host "$Step4$Done" -ForegroundColor Green
        Write-Host ""
        Write-Host "INFO: No version found, took default action to replace files." -ForegroundColor Cyan
      }

      elseif ($NewFileVersion -eq $OldFileVersion)
      {
        Write-Host "$Step3$Done" -ForegroundColor Green
        Write-Host ""
        Write-Host "INFO: Downloaded version $NewFileVersion, current version $OldFileVersion" -ForegroundColor Cyan
        Write-Host "INFO: File versions are equal, keeping existing file." -ForegroundColor Cyan
      }

    }

    else
    {
      Write-Host ""
      Write-Host "INFO: Running instance in download only." -ForegroundColor Cyan
      Write-Information "Unable to find any files in the $FinalApplicationShare directory, if this is supposed to be true nevermind this message, otherwise check the path..."
    }

  }

  catch
  {
    $ErrorMessage = $_.Exception.Message
    Write-Information "Failed to query or replace application with error message: $ErrorMessage" .
    Write-Host "$Step3$Fail" -ForegroundColor Red
    break
  }

}


##################################################################################################################
# Begin processing the XML-data and start up the main functions of the script
##################################################################################################################

Start-Transcript -Path "$LogPath" -Force

#Import XML-data
try
{
  [xml]$DownloadSettings = Get-Content "$PSScriptRoot\DownloadSettings.xml"
}

catch
{
  $ErrorMessage = $_.Exception.Message
  Write-Host "Failed to get settings from $DownloadSettings with error message: $ErrorMessage" .

  break
}

#Awesome special effects
$Step1 = "STEP: Create the download folder..."
$Step2 = "STEP: Download the application... "
$Step3 = "STEP: Compare the applications... "
$Step4 = "STEP: Replace the applications... "

$Done = "`t`t`t`t`t`t`t [DONE]"
$Fail = "`t`t`t`t`t`t`t [FAIL]"
$Skip = "`t`t`t`t`t`t`t [SKIP]"

#Process XML-data
foreach ($Application in $DownloadSettings.xml.Application)
{

  $DownloadURL = $Application.DownloadURL
  $FolderName = $Application.ApplicationName
  $Filename = $Application.Filename
  $Keyword = $Application.Keyword
  
  $FinalDownloadFolder = "$DownloadFolder\$Foldername\Source\"
  $FinalApplicationShare ="$ApplicationShare\$Foldername\Source\"

  #Use these settings if a link is present and keyword and filename are not set
  if (($DownloadURL) -and (!$Keyword) -and (!$Filename))
  {
    $Block = "[1]"
    $FileName = $DownloadURL.Split('/')[-1].Split('?')[0] -replace "%20","_"
  }

  #Use these settings if link and keyword has a value, but filename is not set
  elseif (($DownloadURL) -and ($Keyword) -and (!$Filename))
  {
    $Block = "[2]"
    $DownloadURL = ((Invoke-WebRequest $DownloadURL).Links | Where { $_.href -like "*http*$Keyword*" }).href
    $Filename = $DownloadURL.Split('/')[-1].Split('?')[0] -replace "%20","_"
  }

  #Use these settings if link, keyword and filename all have values
  elseif (($DownloadURL) -and ($Keyword) -and ($Filename))
  {
    $Block = "[3]"
    $DownloadURL = ((Invoke-WebRequest $DownloadURL).Links | Where { $_.href -like "*http*$Keyword" -or $_.innerText -like "$Keyword" }).href
  }

  #Output some useful information to the logs, in case of troubleshooting
  Write-Host ""
  Write-Host "$Foldername" -ForegroundColor White;
  Write-Host "-------------------------------------------------------------------"
  Write-Information "ConditionBlock: $Block"
  Write-Information "DownloadFolder: $FinalDownloadFolder"
  Write-Information "DownloadURL...: $DownloadURL"
  Write-Information "Filename......: $Filename"
  Write-Information "Keyword.......: $Keyword"

  CreateDownloadFolder
  DownloadFiles
  CompareFilesAndReplace

  Write-Host "-------------------------------------------------------------------"
}

Write-Host ""
Stop-Transcript 