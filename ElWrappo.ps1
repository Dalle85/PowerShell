<#
.DESCRIPTION
This is a PowerShell-wrapper for MDT that will install any *.exe or *.msi file located within the source-folder,
so just throw any (or multiple) executable inside the source-folder and the script will try to install it.

However, even though the script potentially could run through multiple executables stored within the source-folder,
the reason we use this script is so that we don't have to worry about changing the name scripts/commandlines every-
time we donload a new version of an application. Unless all files share the same switches for a silent installation.

.USAGE
Make sure that the folder structure looks something like this, give the Application a good name and then import
the folder from your MDT console.

E:.
|____Install - Application - x64
     |_____Source
     |     |_____MyApplication.exe
     |_____ElWrappo.ps1

Set the install command to: PowerShell.exe –ExecutionPolicy ByPass -WindowStyle Hidden –File ElWrappo.ps1
The logfile will be named after what you named your application folder.

.NOTES
Don't ask for help, I'll ask you!

.AUTHOR
Dalle, 2016-05-24, inspired by other Swedish geeks
#>

# Set switches to perform a silent installation
$Switches = "/S"

# Set some variables and then try to load up the TaskSequence Environment and then start logging
$SourcePath = "$PSScriptRoot\Source"
$ScriptName = Split-Path $PSScriptRoot -Leaf

try {
  $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
  $MDTIntegration = "YES"
  $LogPath = $TSEnv.Value("LogPath")
  $LogFile = $LogPath + "\" + "$ScriptName.txt"
}
catch {
  $MDTIntegration = "NO"
  $LogPath = $env:TEMP
  $LogFile = $LogPath + "\" + "$ScriptName.txt"
}

Start-Transcript -Path $LogFile -Force

#Output some shit to the log
Write-Output ""
Write-Output "$ScriptName - ScriptDir: $PSScriptRoot"
Write-Output "$ScriptName - SourcePath: $SourcePath"
Write-Output "$ScriptName - ScriptName: $ScriptName"
Write-Output "$ScriptName - Integration with MDT(LTI/ZTI): $MDTIntegration"
Write-Output "$ScriptName - Log: $LogFile"
Write-Output ""

#Start Wrapping
$Installers = Get-ChildItem -Path $SourcePath -Recurse –Include *.msi, *.exe
$Installers | % {

  if ($_.Name -like "*.exe") {
    Write-Output "Attempting to install $_ with the following switch(es): $Switches"
    Start-Process "$_" "-ArgumentList $Switches -NoNewWindow -Wait"
    Write-Output "Setup finished with exitcode: $LastExitCode"
  }
  elseif ($_.Name -like "*.msi") {
    Write-Output "Attempting to install $_ with the following switch(es): /i $Switches"
    Start-Process msiexec -ArgumentList "/i " $_" $Switches -NoNewWindow -Wait"
    Write-Output "Setup finished with exitcode: $LastExitCode"
  }
}

Write-Output ""
Stop-Transcript
