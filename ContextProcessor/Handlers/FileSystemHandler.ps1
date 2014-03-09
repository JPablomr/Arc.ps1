function FileSystemHandler{
    param($context)
    #I'm lazy, so I copy paste where this searches uses a global Variable for the rootpath
    $fileLocation = $Global:Variables.RootDir + $context.Request.Url.AbsolutePath.Replace("/","\")

    # Should keep Directory Traversal Attacks at bay. 
    $fileLocation -replace "..\",".\"
    
    if(-not (Test-Path $fileLocation)){
        return (404Handler $context)
    }
   
    $responseObject = [System.IO.File]::ReadAllBytes($fileLocation)

    $response = $context.Response

    # Get a response stream and write the response to it.
    $response.ContentLength64 = $responseObject.Length
    $output = $response.OutputStream
    
    $output.Write($responseObject,0,$responseObject.Length)
    #Close the output stream.
    $output.Close()

}