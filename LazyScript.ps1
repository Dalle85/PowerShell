<#
.DESCRIPTION
This script will download the latest executables of the specified applications to .\Downloads using wget

.NOTES
You need to run this script as local administrator

.USAGE
Inspect websites by using the following command:
(wget –URI ‘YOUR_LINK’).Links

.AUTHOR
Dalle, 2016-05-21
#>

#Begin
Clear-Host

$PSHost = Get-Host
$PSWindow = $PSHost.UI.RawUI
$PSWindow.WindowTitle = “LazyScript...”
$Start = Get-Date

Write-Host "Script started..."
Write-Host ""

# Direct links that doesn't change, latest version is always using the same filename
$DURLS = @(
  "http://fpdownload.macromedia.com/pub/flashplayer/latest/help/install_flash_player.exe" # Adobe Flash Player
  "http://eu.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe" # Battle.net
  "https://downloadplugins.citrix.com/Windows/CitrixReceiverWeb.exe" # Citrix Receiver
  "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" # Google Chrome x64
  "https://secure-appldnld.apple.com/itunes12/031-62806-20160516-DC2224E6-1959-11E6-BC22-D2135529DBDF/iTunes6464Setup.exe" # iTunes x64
  "http://mpdn.zachsaw.com/Latest/Installers/MediaPlayerDotNet_x64_Installer.exe" # MediaPlayerDotNet x64
  "https://mpdn.zachsaw.com/Latest/Installers/MPDN-Extensions_Installer.exe" # MediaPlayerDotNet Extensions
  "https://download.skype.com/6b299e4bcff18dc8b24d41ae51d68173/SkypeSetup.msi" # Skype
  "https://download.spotify.com/SpotifySetup.exe" # Spotify
  "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe" # Steam
  "http://download.teamviewer.com/download/TeamViewer_Setup.exe" # TeamViewer
  "https://ubistatic3-a.akamaihd.net/orbit/launcher_installer/UplayInstaller.exe" # Uplay
)

# Redirected links where the filename change, therefore we use the href link to download the latest version
$RURLS = @(
  "http://www.snapfiles.com/downloads/7zip/dl7zip.html" # 7-Zip x64
  "http://www.snapfiles.com/downloads/flashplayerie/dlflashplayerie.html" # Adobe Flash Player for IE
  "https://sourceforge.net/projects/filezilla/files/latest/download" # FileZilla
  "http://www.snapfiles.com/downloads/phoenixmoz/dlphoenixmoz.html" # FireFox
  "http://www.java.com/sv/download/manual.jsp" # Java x64
  "https://sourceforge.net/projects/keepass/files/latest/download" # KeePass
  "http://www.snapfiles.com/downloads/notepadplus/dlnotepadplus.html" #Notepad++
  "http://www.snapfiles.com/downloads/tixati/dltixati.html" # Tixati x64
)

# Check if the download-folder exists, else it will be created.
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

# This function will check if the file exists, if not it will start downloading to the download path
function StartDownloading () {

# Get the file name 
$FileName = $URL.Split('/')[-1].Split('=')[-1]

try {
  # Return true if the file exists, otherwise return false 
  if (!(Test-Path "$DownloadPath\$FileName")) {
    Write-Progress -Activity "Downloading `'$FileName`' to `'$DownloadPath`'" -Status "Please wait..."
    wget "$URL" -OutFile $DownloadPath\$FileName -ErrorVariable Error
    if ($Error) { throw "" }
    Write-Progress -Activity `'$FileName`' -Status "Done." 
    Write-Host "`'$FileName`' " -NoNewline; Write-Host "downloaded successfully!" -ForegroundColor "GREEN"
  }
  else {
    Write-Host "`'$FileName`' " -NoNewLine; Write-Host "already exists, skipping..." -ForegroundColor "YELLOW"
  }
}
catch {
  Write-Host "`'$FileName`' " -NoNewline; Write-Host "failed, check the link and try again..." -ForegroundColor "RED"
  }
}

# Download applications with direct links, nothing else
Write-Host "Processing direct links..."

foreach ($URL in $DURLS) {
  StartDownloading
}

# Download files with redirected links using wget to find the target link
Write-Host ""
Write-Host "Processing redirected links..."

foreach ($URL in $RURLS) {
  $URL = ((wget $URL).Links | 
    Where {
      $_.href -like "*7z*x64*" -or $_.href -like "*filezilla*64*" -or $_.href -like "*flashplayer*" -or
      $_.innerText -like "*offline*64-bit*" -or $_.href -like "*keepass*setup*" -or $_.href -like "*npp*installer*" -or
      $_.href -like "*win64*firefox*" -or $_.href -like "*tixati*64*"
    }).href
  StartDownloading
}

Write-Host ""
Write-Host "Script finished in $((Get-Date).Subtract($Start).Seconds) second(s)."
Write-Host ""

Pause
