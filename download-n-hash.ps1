# bleh
$script = {
    $remote = $args[0]
    $local = $args[1]
    if( Test-Path $remote -pathtype container ) {
        Write-Host "passing on $remote"
        continue
    }

    # the following needs the full path (ugh!!)
    # this func is from:
    # http://gallery.technet.microsoft.com/scriptcenter/Get-FileHash-83ab0189
    Function Get-FileHash([String] $FileName,$HashName = "MD5") {
        $FileStream = New-Object System.IO.FileStream($FileName,[System.IO.FileMode]::Open)
        $StringBuilder = New-Object System.Text.StringBuilder
        [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash($FileStream)|%{[Void]$StringBuilder.Append($_.ToString("x2"))}
        $FileStream.Close()
        $FileStream.Dispose()
        $StringBuilder.ToString()
    }

    Function Get-NetworkFile([String] $FileName, $SaveFile) {
        $webclient = New-Object System.Net.WebClient
        $webclient.DownloadFile($FileName,$SaveFile)
    }

    Get-Random -Minimum 0 -Maximum 5 | sleep
    try {
        Get-NetworkFile $remote $local
        Get-FileHash $local "MD5"
    } finally {
        Get-Random -Minimum 3 -Maximum 7 | sleep
        rm $local
    }
}

$stemp = "c:\script-temp"
$url = "\\nas\justin\script-temp"
$loop = 0
while($true){
    $loop = $loop + 1
    
    Write-Output ""
    Write-Output ""
    Write-Output "##################################################"
    Write-Output ""
    Write-Output "Starting the process"
    Write-Output "Iteration number: $loop"
    Write-Output ""
    Write-Output "##################################################"
    Write-Output ""
    Write-Output ""
    
    Write-Output "##################################################"
    Write-Output ""
    Write-Output "Making temp dir: $stemp\$loop"
    Write-Output ""
    Write-Output "##################################################"
    mkdir "$stemp\$loop"
    
    foreach( $file in dir $url ) {
        Write-Output "##################################################"
        Write-Output ""
        Write-Output "Working with: $file"
        Write-Output ""
        Write-Output "##################################################"
        
        start-job -ArgumentList @("$url\$file", "$stemp\$loop\$file") -ScriptBlock $script
    }
    Get-Random -Minimum 6 -Maximum 10 | sleep

    Write-Output "##################################################"
    Write-Output ""
    Write-Output "Cleaning temp dirs"
    foreach( $dirNum in dir $stemp ) {
        Write-Output ""
        Write-Output "Trying $dirNum"
        Write-Output ""

        $dirInfo = Get-ChildItem "$stemp\$dirNum" | Measure-Object
        Write-Output "$stemp\$dirNum has $($dirInfo.Count) item(s)"
        
        if ( $dirInfo.Count -eq 0 ){
            Write-Output "Removing: $stemp\$dirNum"
            rmdir "$stemp\$dirNum"
        } else {
            Write-Output "Not removing: $stemp\$dirNum"
        }
        Write-Output ""
    }
    
    Write-Output ""
    Write-Output "##################################################"

    
    Write-Output "##################################################"
    Write-Output ""
    Write-Output "After starting iteration $loop"
    Write-Output "we're sleeping for a bit..."
    Write-Output ""
    Write-Output "##################################################"
    Get-Random -Minimum 20 -Maximum 40 | sleep
}
