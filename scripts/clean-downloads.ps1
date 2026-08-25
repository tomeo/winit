# Moves everything in Downloads older than 30 days to the Recycle Bin.
# -OlderThanDays changes the threshold; the Recycle Bin makes it undoable.
param([int]$OlderThanDays = 30)

Add-Type -AssemblyName Microsoft.VisualBasic
$Cutoff = (Get-Date).AddDays(-$OlderThanDays)
$Items = @(Get-ChildItem "$env:USERPROFILE\Downloads" -Force | Where-Object { $_.LastWriteTime -lt $Cutoff })

foreach ($Item in $Items) {
    if ($Item.PSIsContainer) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Item.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Item.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
    Write-Host "  recycled $($Item.Name)"
}
Write-Host "$($Items.Count) item(s) older than $OlderThanDays days moved to the Recycle Bin."
