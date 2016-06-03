<#

.SYNOPSIS
This is a simple Powershell script to install any files located within the application
folder of your deployment share.

.DESCRIPTION
Even though this script will work standalone, this Powershell-wrapper is intended
to use in conjunction with my other script - KeepItUpdated.ps1 (a script to automatically
download the latest executables e web and replace the files in your deployment share.

The script will install any *.exe or *.msi file located within the source folder,
so just throw any (or multiple) executable inside the source folder and the script will
try to install it.

This script can install multiple multiple executables stored within the source-folder,
but we will only be passing the the silent switch once, the reason we use this script
is rather so that we don't have to change the the scripts or commandlines everytime
we download a new version of an application.

.EXAMPLE
You need to use the following structure for the script to work.

.\Install - MyApplication (Latest) - x86-x64
.\Install - MyApplication (Latest) - x86-x64\ElWrappo.ps1
.\Install - MyApplication (Latest) - x86-x64\Source
.\Install - MyApplication (Latest) - x86-x64\Source\MyApplication.exe

Make sure you give the application and folder a good name, as the logfile will use the
same name as that of your folder. Import the application to your console, either by
using the console or scripts, then set the install command to:

PowerShell.exe –ExecutionPolicy ByPass -WindowStyle Hidden –File ElWrappo.ps1

.DISCLAIMER
This script is provided "AS IS" with no warranties, confers no rights and
is not supported by the author.

.AUTHOR
Victor Dahlberg, Office IT-Partner

.DATE
2016-06-02

.LINK
http://deployman.wordpress.com

#>

######################################################################################
# Set variables
######################################################################################

# Switch to perform a silent installation
$Switches = "/S"

$SourcePath = "$PSScriptRoot\Source"
$ScriptName = Split-Path $PSScriptRoot -Leaf


######################################################################################
# Try to import the TaskSequence Environment
######################################################################################

try
{
  $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
  $MDTIntegration = "YES"
  $LogPath = $TSEnv.Value("LogPath")
  $LogFile = $LogPath + "\" + "$ScriptName.txt"
}

catch
{
  $MDTIntegration = "NO"
  $LogPath = $env:TEMP
  $LogFile = $LogPath + "\" + "$ScriptName.txt"
}


######################################################################################
# Start logging and output some useful information to the logfile
######################################################################################

Start-Transcript -Path $LogFile -Force

Write-Information "$ScriptName"
Write-Information "-------------------------------------------------"
Write-Information "ScriptDir.....: $PSScriptRoot"
Write-Information "SourcePath....: $SourcePath"
Write-Information "ScriptName....: $ScriptName"
Write-Information "MDTIntegration: $MDTIntegration"
Write-Information "Log...........: $LogFile"
Write-Information ""


######################################################################################
# Start wrapping
######################################################################################

$Installers = Get-ChildItem -Path $SourcePath -Recurse –Include *.msi, *.exe
$Installers | % {

  if ($_.Name -like "*.exe")
  {
    Write-Host "Attempting to install $_ with the following switch(es): $Switches"
    Start-Process "$_" "-ArgumentList $Switches -NoNewWindow -Wait"
    Write-Host "Setup finished with exitcode: $LastExitCode"
  }
  
  elseif ($_.Name -like "*.msi")
  {
    Write-Host "Attempting to install $_ with the following switch(es): /i $Switches"
    Start-Process msiexec -ArgumentList "/i  $_ $Switches -NoNewWindow -Wait"
    Write-Host "Setup finished with exitcode: $LastExitCode"
  }

  elseif ($_.Name -like "*.ps1")
  {
    Write-Host "Attempting to run script $_"
    Start-Process "$_ " "-ArgumentList -ExecutionPolicy Bypass -NoNewWindow -Wait"
    Write-Host "Script finished with exitcode: $LastExitCode"
  }

  elseif ($_.Name -like "*.cmd" -or "*.bat")
  {
    Write-Host "Attempting to run script $_"
    Start-Process "$_ " "-ArgumentList -NoNewWindow -Wait"
    Write-Host "Script finished with exitcode: $LastExitCode"
  }

  elseif ($_.Name -like "*.reg")
  {
    Write-Host "Attempting to import $_ to the registry:"
    Start-Process "reg import $_ " "-ArgumentList -NoNewWindow -Wait"
    Start-Process cmd -ArgumentList "/c reg import $_ -NoNewWindow -Wait"
    Write-Host "Import finished with exitcode: $LastExitCode"
  }

}

Write-Information ""
Stop-Transcript
