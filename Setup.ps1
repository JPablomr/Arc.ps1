# netsh http add urlacl url=http://localhost:8777/ user=$(whoami)

param(
    $webroot = "",
    $port = "",
    $variablesFilePath = "$(Split-Path $MyInvocation.MyCommand.Path)\variables.ps1",
    $webListenerPath = "$(Split-Path $MyInvocation.MyCommand.Path)\Listener\Listener.ps1",
    $webRequestHandlerPath = "$(Split-Path $MyInvocation.MyCommand.Path)\ContextProcessor\DefaultContextProcessor.ps1",
    [switch] $daemonize
)

function ReserveNetsh{
    if(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
        Write-Host "Creating netsh URL Reservation for http://$($Global:Variables.IpAddress):$($Global:Variables.Port)"
        netsh http add urlacl url=http://$($Global:Variables.IpAddress):$($Global:Variables.Port)/ user=$(whoami)
    }
    else{
        Write-Host "Creating netsh URL Reservation for http://$($Global:Variables.IpAddress):$($Global:Variables.Port)"
        Write-Host "We don't have administrator privileges to create the netsh reservation. Hang on, I'll retry as admin"
        Start-Process powershell -Verb runAs -ArgumentList "-command `"netsh http add urlacl url=http://$($Global:Variables.IpAddress):$($Global:Variables.Port)/ user=$(whoami)`"" 
    }
}

Write-Debug "Loading Variables File at $variablesFilePath"

. $variablesFilePath

if($webroot -ne ""){
    $Global:Variables.RootDir = $webroot
}
if($port -ne ""){
    $Global:Variables.Port = $webroot
}




Write-Host "Testing for netsh reservation..."
$netshReserved = netsh http show urlacl | Select-String -Quiet " http://$($Global:Variables.IpAddress):$($Global:Variables.Port)"
if($netshReserved -ne $true){ReserveNetsh} 
else {Write-Host "Reservation already done."}


if($daemonize){
    $srv = Start-Process -WindowStyle "Hidden" powershell -ArgumentList "-noexit -nologo -file $webListenerPath -variablesFile $variablesFilePath -contextProcessorPath $webRequestHandlerPath" -PassThru
    Write-Host "You'll have to kill the following PID: $($srv.Id)"
}
else{
    Write-Host "Loading Listener File at $webListenerPath"
    . $webListenerPath -contextProcessorPath $webRequestHandlerPath

    Write-Host "Server will die once you close me."
}