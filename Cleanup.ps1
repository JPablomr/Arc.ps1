# netsh http add urlacl url=http://localhost:8777/ user=$(whoami)

param(
    $variablesFilePath = "$(Split-Path $MyInvocation.MyCommand.Path)\variables.ps1"
)



function Cleanup-Webserver{
     Write-Host "Removing netsh URL Reservation for http://$($Global:Variables.IpAddress):$($Global:Variables.Port)"
if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
       
        netsh http delete urlacl url=http://$($Global:Variables.IpAddress):$($Global:Variables.Port)/
    }
    else{
        Write-Host "Creating netsh URL Reservation for http://$($Global:Variables.IpAddress):$($Global:Variables.Port)"
        Write-Host "We don't have administrator privileges to delete the netsh reservation. Hang on, I'll retry as admin"
        Start-Process powershell -Verb runAs -ArgumentList "-command `"netsh http delete urlacl url=http://$($Global:Variables.IpAddress):$($Global:Variables.Port)/`"" 
    }
}

Cleanup-Webserver