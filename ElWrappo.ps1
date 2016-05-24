<#

.DESCRIPTION
This is a PowerShell-wrapper for MDT that will install any *.exe or *.msi file located within the source-folder,
so just throw one, or multiple, executables inside this folder and the script will try to install them.

However, even if the script will run through any executables inside the source-folder, we will only be
passing the one argument, so for that reason there should only be one application inside the source-folder,
unless all files share the same switches for a silent installation.

.USAGE
Make sure that the folder structure looks something like this, then import the application and give it a good name.

C:\
├─── Source
│    └─── MyExecutable.msi
└─── Install_Wrapper.ps1

Set the install command to:
PowerShell.exe –ExecutionPolicy ByPass -WindowStyle Hidden –File Install_Wrapper.ps1

Logfile will always be named after the folder where the script is located, let's say it would be stored in:
"\\SERVER\MDTProduction$\Applications\Install - 7-Zip (Latest) - x64"
In that case the filename will be "Install - 7-Zip (Latest) - x64.txt"

.NOTES
Don't ask for help, I'll ask you!

.AUTHOR
Dalle, 2016-05-24, inspired by other Swedish geeks

#>


# ---------------------------------------------------------------------------------------------------------------------------
# Set switches to perform a silent installation
# ---------------------------------------------------------------------------------------------------------------------------

$Switches = "/S"


# ---------------------------------------------------------------------------------------------------------------------------
# Set some variables and then try to load up the TaskSequence Environment and then start logging
# ---------------------------------------------------------------------------------------------------------------------------

$SourcePath = "$PSScriptRoot\Source"
$ScriptName = Split-Path $PSScriptRoot -Leaf

try {
  $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
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


# ---------------------------------------------------------------------------------------------------------------------------
# Output some information to the log-file
# ---------------------------------------------------------------------------------------------------------------------------

Write-Output ""
Write-Output "$ScriptName - ScriptDir: $PSScriptRoot"
Write-Output "$ScriptName - SourcePath: $SourcePath"
Write-Output "$ScriptName - ScriptName: $ScriptName"
Write-Output "$ScriptName - Integration with MDT(LTI/ZTI): $MDTIntegration"
Write-Output "$ScriptName - Log: $LogFile"
Write-Output ""


# ---------------------------------------------------------------------------------------------------------------------------
# Search source-path for files ending with .msi or .exe, then try to install them one at a time and finally stop logging
# ---------------------------------------------------------------------------------------------------------------------------

$Installers = Get-ChildItem "-Path $SourcePath -Recurse –Include *.msi, *.exe"
$Installers | % {

  if ($_.Name -like "*.exe") {
    Write-Output "Attempting to install $_ with the following switch(es): $Switches"
    Start-Process "$_" "-ArgumentList $Switches -NoNewWindow -Wait"
    Write-Output "Setup finished with exitcode $LastExitCode"
  }

  elseif ($_.Name -like "*.msi") {
    Write-Output "Attempting to install $_ with the following switch(es): /i $Switches"
    Start-Process msiexec -ArgumentList "/i "$_" $Switches -NoNewWindow -Wait"
    Write-Output "Setup finished with exitcode $LastExitCode"
  }
}

Write-Output ""
Stop-Transcript
