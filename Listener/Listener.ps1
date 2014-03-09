# netsh http add urlacl url=http://localhost:8777/ user=$(whoami)
param(
    $variablesFile = $null,
    $contextProcessorPath  = $null
)
if($variablesFile -ne $null){
Write-Host "Loading Variables File at $variablesFile"
. $variablesFile
}
if($contextProcessorPath -ne $null){
Write-Host "Loading Request Handler File at $contextProcessorPath"
. $contextProcessorPath
}

$listener = New-Object System.Net.HttpListener
if($RequestProcessor -eq $null){
    $HandlerPipeline = {
        param($context) 
        $responseObject = [System.Text.Encoding]::UTF8.GetBytes("It works!")
        $response = $context.Response
        # Get a response stream and write the rsponse to it.
        $response.ContentLength64 = $responseObject.Length
        $output = $response.OutputStream
    
        $output.Write($responseObject,0,$responseObject.Length)
        # You must close the output stream.
        $output.Close()
    }
}
else{
    $HandlerPipeline =  $RequestProcessor
}
#region CallbackFunction
# Thanks to http://poshcode.org/1382
function New-ScriptBlockCallback {
    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [scriptblock]$Callback
    )

   # is this type already defined?    
    if (-not ("CallbackEventBridge" -as [type])) {
        Add-Type @"
            using System;
            
            public sealed class CallbackEventBridge
            {
                public event AsyncCallback CallbackComplete = delegate { };

                private CallbackEventBridge() {}

                private void CallbackInternal(IAsyncResult result)
                {
                    CallbackComplete(result);
                }

                public AsyncCallback Callback
                {
                    get { return new AsyncCallback(CallbackInternal); }
                }

                public static CallbackEventBridge Create()
                {
                    return new CallbackEventBridge();
                }
            }
"@
    }
    $bridge = [callbackeventbridge]::create()
    Register-ObjectEvent -input $bridge -EventName callbackcomplete -action $callback -messagedata $args > $null
    $bridge.Callback
}
#endregion

function Start-Server{
    $url = "http://$($Global:Variables.IpAddress):$($Global:Variables.Port)/"

    Write-Host "Starting Listener at $url"
    $listener.Prefixes.Add($url)
    $listener.Start()

    Write-Debug "Listening for requests"
    $listener.BeginGetContext((New-ScriptBlockCallback $RequestListener),$listener)
    
}
function Stop-Server{
    Write-Host "Finished Listening for requests. Shutting down Server."
    $listener.Close()
}

$RequestListener={
    param($result)
    [System.Net.HttpListener]$listener = $result.AsyncState;
    # Call EndGetContext to complete the asynchronous operation.
    $context = $listener.EndGetContext($result);
  
   <#  
    $response = $context.Response
    # Get a response stream and write the rsponse to it.
    $response.ContentLength64 = $responseObject.Length
    $output = $response.OutputStream
    
    $output.Write($responseObject,0,$responseObject.Length)
    # You must close the output stream.
    $output.Close()
    #>

    # Hand off the Context to the Handler, he's in charge of responding.
    Write-Debug "[Listener] Sending request to Handler Function"

    & $HandlerPipeline $context  

    $listener.BeginGetContext((New-ScriptBlockCallback $RequestListener),$listener)
}


Start-Server