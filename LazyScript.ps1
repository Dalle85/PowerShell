<#
.DESCRIPTION
This script will download the latest executables of the specified applications to .\Downloads using Invoke-Webrequest

.NOTES
You need to run this script as local administrator

.USAGE
Inspect websites by using the following command:
(Invoke-Webrequest –URI ‘YOUR_LINK’).Links

.AUTHOR
Dalle, 2016-05-21
#>

# Direct links that doesn't change, latest version is always using the same filename
$DURLS = @(
  #Adobe Flash Player
  "http://fpdownload.macromedia.com/pub/flashplayer/latest/help/install_flash_player.exe"
  #Battle.net
  "http://eu.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"
  #Citrix Receiver
  "https://downloadplugins.citrix.com/Windows/CitrixReceiverWeb.exe"
  #Google Chrome x64
  "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
  #iTunes x64
  "https://secure-appldnld.apple.com/itunes12/031-62806-20160516-DC2224E6-1959-11E6-BC22-D2135529DBDF/iTunes6464Setup.exe"
  #MediaPlayerDotNet x64
  "http://mpdn.zachsaw.com/Latest/Installers/MediaPlayerDotNet_x64_Installer.exe"
  #MediaPlayerDotNet Extensions
  "https://mpdn.zachsaw.com/Latest/Installers/MPDN-Extensions_Installer.exe"
  #Skype
  "https://download.skype.com/6b299e4bcff18dc8b24d41ae51d68173/SkypeSetup.msi"
  #Spotify
  "https://download.spotify.com/SpotifySetup.exe"
  #Steam
  "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
  #TeamViewer
  "http://download.teamviewer.com/download/TeamViewer_Setup.exe"
  #Uplay
  "https://ubistatic3-a.akamaihd.net/orbit/launcher_installer/UplayInstaller.exe"
)

#Redirected links where the final link is dynamic, instead we inspect the website and find the href link to download the latest version
$RURLS = @(
  #7-Zip x64
  "http://www.snapfiles.com/downloads/7zip/dl7zip.html"
  #Adobe Flash Player for IE
  "http://www.snapfiles.com/downloads/flashplayerie/dlflashplayerie.html"
  #FileZilla
  "https://sourceforge.net/projects/filezilla/files/latest/download"
  #FireFox
  "http://www.snapfiles.com/downloads/phoenixmoz/dlphoenixmoz.html"
  #Java x64
  "http://www.java.com/sv/download/manual.jsp"
  #KeePass
  "https://sourceforge.net/projects/keepass/files/latest/download"
  #Notepad++
  "http://www.snapfiles.com/downloads/notepadplus/dlnotepadplus.html"
  #Tixati x64
  "http://www.snapfiles.com/downloads/tixati/dltixati.html"
)

#Check if download-folder exists, else it will be created.
function CreateDownloadPath () {

  $DownloadPath = "$PSScriptRoot\Downloads"

  try {
    #Return true if the Destination Folder exists, otherwise return false 
    if (!(Test-Path "$DownloadPath" -PathType Container)) {   
      #Creates the destination folder if it does not exist 
      New-Item $DownloadPath -ItemType Directory | Out-Null
      Write-Information "$DownloadPath does not exist, creating..."
    }
  }
  catch {
    Write-Warning "An error occurred while creating the destination folder (`'$DownloadPath`'), please check the path and try again."
    break
  }
}

#Check if the file exists, oterwise start downloading
function StartDownloading () {

  #Get the file name 
  $FileName = $URL.Split('/')[-1].Split('=')[-1]

  try {
    #Return true if the file exists, otherwise return false 
    if (!(Test-Path "$DownloadPath\$FileName")) {
      Write-Progress -Activity "Downloading `'$FileName`' to `'$DownloadPath`'" -Status "Please wait..."
      #Try to download the file, otherwise output error message
      Invoke-Webrequest "$URL" -OutFile $DownloadPath\$FileName -ErrorVariable Error
      if ($Error) { throw "" }
      Write-Host "`'$FileName`' downloaded successfully!" -ForegroundColor "GREEN"
    }

    else {
      Write-Host "`'$FileName`' already exists, skipping..." -ForegroundColor "YELLOW"
    }
  }

  catch {
    Write-Host "`'$FileName`' failed, check the link and try again..." -ForegroundColor "RED"
  }
}

#Begin
CreateDownloadPath

#Download using direct link
foreach ($URL in $DURLS) {
  StartDownloading
}

#Find the target link and download it
foreach ($URL in $RURLS) {
  $URL = ((Invoke-Webrequest $URL).Links |
    Where {
      $_.href -like "*7z*x64*" -or
      $_.href -like "*filezilla*64*" -or
      $_.href -like "*flashplayer*" -or
      $_.href -like "*keepass*setup*" -or
      $_.href -like "*npp*installer*" -or
      $_.href -like "*win64*firefox*" -or
      $_.href -like "*tixati*64*" -or
      $_.innerText -like "*offline*64-bit*"
    }
  ).href
  StartDownloading
}
