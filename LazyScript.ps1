<#
.DESCRIPTION
This script will download the latest executables of the specified applications to .\Downloads using Invoke-Webrequest

.NOTES
You need to run this script as local administrator

.AUTHOR
Dalle, 2016-05-21

#>


# ------------------------------------------------------------------------------------------------------------------------
# Start fresh
# ------------------------------------------------------------------------------------------------------------------------

Clear-Host

$PSHost = Get-Host
$PSWindow = $PSHost.UI.RawUI
$PSWindow.WindowTitle = “Too lazy to download manually...”
$Start = Get-Date

Write-Host "Script started..."
Write-Host ""


# ------------------------------------------------------------------------------------------------------------------------
# Direct links that doesn't change, latest version is always using the same filename
# ------------------------------------------------------------------------------------------------------------------------

$DURLS = @(

  # Battle.net
  "http://eu.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"
  # Google Chrome x64
  "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
  # iTunes x64
  "https://secure-appldnld.apple.com/itunes12/031-62806-20160516-DC2224E6-1959-11E6-BC22-D2135529DBDF/iTunes6464Setup.exe"
  # MediaPlayerDotNet x64
  "http://mpdn.zachsaw.com/Latest/Installers/MediaPlayerDotNet_x64_Installer.exe"
  # MediaPlayerDotNet Extensions
  "https://mpdn.zachsaw.com/Latest/Installers/MPDN-Extensions_Installer.exe"
  # Skype
  "https://download.skype.com/6b299e4bcff18dc8b24d41ae51d68173/SkypeSetup.msi"
  # Spotify
  "https://download.spotify.com/SpotifySetup.exe"
  # Steam
  "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
  # Uplay
  "https://ubistatic3-a.akamaihd.net/orbit/launcher_installer/UplayInstaller.exe"
)


# ------------------------------------------------------------------------------------------------------------------------
# Redirected links where the filename change, therefore we use the href link to download the latest version
# ------------------------------------------------------------------------------------------------------------------------

$RURLS = @(

  # 7-Zip x64
  "http://www.snapfiles.com/downloads/7zip/dl7zip.html"
  # Tixati x64
  "http://www.snapfiles.com/downloads/tixati/dltixati.html"
)


# ------------------------------------------------------------------------------------------------------------------------
# Destination folder where the files will be downloaded, create if it does not exist
# ------------------------------------------------------------------------------------------------------------------------

# Change this one if necessary
$DownloadPath = "$PSScriptRoot\Downloads"

try {

  # Return true if the Destination Folder exists, otherwise return false 
  if (!(Test-Path "$DownloadPath" -PathType container)) {

    # Creates the destination folder if it does not exist 
    New-Item $DownloadPath -ItemType Directory | Out-Null
    
    Write-Host "$DownloadPath does not exist, creating..."
    Write-Host ""
  }
}

catch {

  Write-Host "An error occurred while creating the destination folder (`'$DownloadPath`'), please check the path and try again."
  break
}


# ------------------------------------------------------------------------------------------------------------------------
# This function will check if the file exists, if not it will start downloading to the download path
# ------------------------------------------------------------------------------------------------------------------------

function StartDownloading () {

# Get the file name 
$FileName = $URL.Split('/')[-1].Split('=')[-1]

try {

  # Return true if the file exists, otherwise return false 
  if (!(Test-Path "$DownloadPath\$FileName")) {
    
    Write-Host "$FileName... " -NoNewline
    wget $URL -OutFile $DownloadPath\$FileName -ErrorVariable Error
    if ($Error) { throw "" }
    Write-Host "`Done." -ForegroundColor "GREEN"
  }

  else {

    Write-Host "$FileName already exists, skipping..." -ForegroundColor "Yellow"
  }
}

catch {

  Write-Host "An error occurred while downloading `'$FileName`'" -ForegroundColor "RED"
  }
}


# ------------------------------------------------------------------------------------------------------------------------
# Download files with direct links, nothing else
# ------------------------------------------------------------------------------------------------------------------------

Write-Host "Processing direct links..."

foreach ($URL in $DURLS) {

  StartDownloading
}


# ------------------------------------------------------------------------------------------------------------------------
# Download files with redirected links using Invoke-Rebrequest to find the target link
# Inspect websites by using the following command: (Invoke-WebRequest –URI ‘LINK’).Links
# ------------------------------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "Processing redirected links..."

foreach ($URL in $RURLS) {

  $URL = ((wget $URL).Links | `
       Where {$_.href -like "*7z*x64*" -or $_.href -like "*tixati*64*"}).href
       
  StartDownloading
}


# ------------------------------------------------------------------------------------------------------------------------
# Happy ending
# ------------------------------------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "Script finished in $((Get-Date).Subtract($Start).Seconds) second(s)."
Write-Host ""

Pause
