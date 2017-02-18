<#
 
.AUTHOR
    Victor Dahlberg, Office IT-Partner, 2017-02-17
 
.VERSION
    1.2
 
.SYNOPSIS
    This script will attempt to silently install or run each of the follow extensions: *.exe, *.msi, *.ps1, *.cmd, *.bat, *.reg
    You will need to add an extra switch to exe-files to make it install silently, msi-files will always install silently and if an MST or MSP-file is found
    in the source folder the script will automatically add it to the installer arguments.
 
.EXAMPLE
    Add any extra switch and run the script standalone or as an imported application in MDT/SCCM.
        MSI-files will always install silently, but you might want to add extra switches such as "/ALLOWADDSTORE=N" to a Citrix Receiver installation.
        EXE-files will need a switch as the silent argument can sometimes differ.
 
    Execute an imported application with the following parameters:
       PowerShell.exe –ExecutionPolicy ByPass -WindowStyle Hidden -NonInteractive -NoProfile –File ElWrappo.ps1
 
.WARNING
    This script is provided "AS IS" with no warranties and is not supported by the author.
 
#>
 
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 
# Optional switches for a silent install
$extraSwitches = ""
 
# Set source folder
$sourceFolder = Join-Path -Path $PSScriptRoot -ChildPath "Source"
 
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Start-Logging: Try to import TaskSequence Environment, return location for logs and start logging
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 
function Start-Logging {
   
    try {
        $ts = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
   
        if ($ts.Value("LogPath") -ne "") {
            $logPath = $ts.Value("LogPath")
        }
 
        else {
            $logPath = $ts.Value("_SMSTSLogPath")
        }
    }
 
    catch {
        $logPath = $ENV:TEMP
    }
 
    finally {
        $logName = Split-Path -Path $MyInvocation.ScriptName -Leaf
        $logDir = Join-Path -Path $LogPath -ChildPath "$($LogName).log"
 
        Start-Transcript -Path $LogDir -Force -Append | Out-Null
    }
}
 
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Stop-Logging:
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 
function Stop-Logging {
    Stop-Transcript
}
 
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# ProcessFiles: Install or run all files in the source folder
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 
function ProcessFiles {
    param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$sourceFolder,
 
        [Parameter(Mandatory=$false)]
        [AllowNull()]
        [string]$extraSwitches
    )
 
    begin {
        $ErrorActionPreference = "Stop"
    }
 
            process {
       
        # Specify which extensions to include in the search, not all are supported
        $extensions = "*.exe", "*.msi", "*.ps1", "*.cmd", "*.bat", "*.reg"
 
        # Look in source folder for extensions to process
        foreach ($item in Get-ChildItem $sourceFolder -Include $extensions -Recurse) {
 
            Write-Information "Processing $item..."
 
            try {
 
                # -----------------------------------------------------------------------------------------------------------------------------------------------
                # Windows executables
                # -----------------------------------------------------------------------------------------------------------------------------------------------
 
                if ($item.Extension -eq ".exe") {
 
                    $installArgs = @()
               
                    # Add extra switches
                    if ($extraSwitches) {
                                         $installArgs += $extraSwitches
                    }
               
                    $installArgs = $installArgs -join " "
 
                    Write-Information "Using switches '$installArgs'"
                    Start-Process -FilePath "$item" -ArgumentList $installArgs -Wait
                }
 
                # -----------------------------------------------------------------------------------------------------------------------------------------------
                # Windows installers
                # -----------------------------------------------------------------------------------------------------------------------------------------------
 
                elseif ($item.Extension -eq ".msi") {
 
                    $mstFilePath = Get-ChildItem $SourceFolder -Include "*.mst" -Recurse
                    $mspFilePath = Get-ChildItem $SourceFolder -Include "*.msp" -Recurse
 
                    $installArgs = @()
                    $installArgs += "/i `"$item`" /qn"
 
                    # Apply transform if MST-file is found
                    if ($mstFilePath) {
                        $installArgs += "TRANSFORMS=`"$mstFilePath`""
                    }
               
                    # Apply patch if MSP-file is found                  
                    if ($mspFilePath) {
                        $installArgs += "PATCH=`"$mspFilePath`""
                    }
 
                    # Add extra switches
                    if ($extraSwitches) {
                        $installArgs += $extraSwitches
                    }
 
                    $installArgs += "REBOOT=ReallySuppress ALLUSERS=1"
                    $installArgs = $installArgs -join " "
 
                    Write-Information "Using switches '$installArgs'"
                    Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait
                }
 
                # -----------------------------------------------------------------------------------------------------------------------------------------------
                # PowerShell-scripts
                # -----------------------------------------------------------------------------------------------------------------------------------------------
 
                elseif ($item.Extension -eq ".ps1") {
                    Invoke-Expression "& `"$item`"" | Out-Null
                }
 
                # -----------------------------------------------------------------------------------------------------------------------------------------------
                # Batch-scripts
                # -----------------------------------------------------------------------------------------------------------------------------------------------
                   
                elseif ($item.Extension -eq ".cmd" -or ".bat") {
                    Start-Process -FilePath "$item" -Wait
                }
          
                # -----------------------------------------------------------------------------------------------------------------------------------------------
                # Registry values
                # -----------------------------------------------------------------------------------------------------------------------------------------------
                  
                elseif ($item.Extension -eq ".reg") {
                    Start-Process -FilePath "cmd.exe" -WindowStyle Minimized -ArgumentList '/c reg import "' + $item + '"' -Wait
                }
 
                Write-Information "Finished processing $item..."
            }
 
            catch {
                    Write-Warning "Failed to process! $($_.Exception.Message)"
            }
        }
    }
}
 
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Call functions
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 
Start-Logging
ProcessFiles -sourceFolder $sourceFolder -extraSwitches $extraSwitches
Stop-Logging
