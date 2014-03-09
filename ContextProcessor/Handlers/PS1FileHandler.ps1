function PS1Handler{
    param($context)
    #I'm lazy, so this searches uses a global Variable for the rootpath
    $fileLocation = $Global:Variables.RootDir + $context.Request.Url.AbsolutePath.Replace("/","\")
    
    if(-not (Test-Path $fileLocation)){
        return (404Handler $context)
    }
    try{
        $commandOutput = powershell -file $fileLocation
    }
    catch{
        return (500Handler $context)
    }
    $responseObject = [System.Text.Encoding]::UTF8.GetBytes($commandOutput)

    $response = $context.Response

    # Get a response stream and write the response to it.
    $response.ContentLength64 = $responseObject.Length
    $output = $response.OutputStream
    
    $output.Write($responseObject,0,$responseObject.Length)
    #Close the output stream.
    $output.Close()
}
