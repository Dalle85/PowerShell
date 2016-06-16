Import-Module ActiveDirectory
$Domain = Get-ADDomain | Select-Object -ExpandProperty DNSRoot
Import-Module GroupPolicy

#Define Functions
function Get-Unlinked
{

  Write-Host "GPOs not linked (scoped) to an OU "
  Write-Host "--------------------------------- "
  Get-GPO -All | % {
    if ($_ | Get-GPOReport -ReportType XML | Select-String -NotMatch "<LinksTo>")
    {
      Write-Host $_.DisplayName
    }
  }
  Write-Host
}

function Get-Disabled
{
  Write-Host "GPOs where status = 'All Settings Disabled'"
  Write-Host "-------------------------------------------"
  Get-GPO -All | Where-Object { $_.GPOStatus -eq "AllSettingsDisabled" } | Select-Object -ExpandProperty DisplayName
  Write-Host
}

function Get-NoSettings
{
  Write-Host "GPOs with no defined settings "
  Write-Host "----------------------------- "
  Get-GPO -All |
  % {
    if ($_ | Get-GPOReport -ReportType XML | Select-String -NotMatch "<ExtensionData>")
    {
      Write-Host $_.DisplayName
    }
  }
  Write-Host
}

#Produce Report
cls
Write-Host "Inspecting Group Policy for" $Domain -NoNewline -ForegroundColor Yellow; Write-Host "..." -ForegroundColor Yellow
Start-Sleep -s 2
Get-Unlinked
Get-Disabled
Get-NoSettings
Write-Host "Inspection completed, consider removing the GPOs above as they are currently not doing anything..." -ForegroundColor Yellow
Write-Host
Read-Host -Prompt "Press Enter to exit"