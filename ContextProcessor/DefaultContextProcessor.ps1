
# 404 is defined in the Default Processor. Can be Overriden in the Handlers Folder.
function 404Handler{
    param($context)
    Write-Debug "[ScriptProcessor] 404 Handler Called"
    $responseObject = [System.Text.Encoding]::UTF8.GetBytes("404 File Not Found.")
    $response = $context.Response
    $response.StatusCode = 404

    # Get a response stream and write the response to it.
    $response.ContentLength64 = $responseObject.Length
    $output = $response.OutputStream
    
    $output.Write($responseObject,0,$responseObject.Length)
    #Close the output stream.
    $output.Close()
}


# Default 500 Handler. Can be Overriden in the Handlers Folder.

Write-Debug "Loading handlers from $(Split-Path $MyInvocation.MyCommand.Path)\Handlers"
gci "$(Split-Path $MyInvocation.MyCommand.Path)\Handlers" | ? {-not $_.PSIsContainer}| % {. $_.FullName}

function 500Handler{
    param($context)
    Write-Debug "[ScriptProcessor] 500 Handler Called"
    $responseObject = [System.Text.Encoding]::UTF8.GetBytes("500 Internal Server Error. Info:`r`n$($Error[0])")
    $response = $context.Response
    $response.StatusCode = 500

    # Get a response stream and write the response to it.
    $response.ContentLength64 = $responseObject.Length
    $output = $response.OutputStream
    
    $output.Write($responseObject,0,$responseObject.Length)
    #Close the output stream.
    $output.Close()
}

function DetermineHandler{
    param($UrlPath)

    $extension = $UrlPath.Substring($UrlPath.LastIndexOf(".")+1)
    Write-Debug "[ScriptProcessor]Request extension: $extension"
    if($extension -ne $null){
        switch ($extension){
            "ps1" {return "PS1Handler"}
            default {return "FileSystemHandler"}
        }
    }
    else{
        return "404handler"
    }
}

<#
 The context Processor receives an HttpListenerContext Object.
 you can do anything here, just rember you have to return the response!

 This Request Processor handles the following at the moment:

    - Powershell Scripts on the host
    - File System Access
#>


$RequestProcessor = {
    param($Context)

    Write-Debug "[ScriptProcessor]Recieved Context"
    $handler = DetermineHandler $Context.Request.Url.AbsolutePath
    Write-Debug "[ScriptProcessor]Handler To Use:$handler"
    try{
        & $handler $Context
        Write-Debug "[ScriptProcessor]Handler called successfully"
    }
    catch{
        500Handler $Context
    }
}