
[void] [Reflection.Assembly]::LoadWithPartialName( 'System.Windows.Forms' )

Write-Output "Select a Folder"

$d = New-Object Windows.Forms.FolderBrowserDialog
$d.ShowDialog( )

Write-Output "You have selected: " $d.SelectedPath

