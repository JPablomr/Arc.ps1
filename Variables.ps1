# Global Server Variables

$Global:Variables = @{
    RootDir="$(Split-Path $MyInvocation.MyCommand.Path)\webroot"; # Root Directory for the application
    IpAddress="127.0.0.1";
    Port="44380" # A port like any other port
}
