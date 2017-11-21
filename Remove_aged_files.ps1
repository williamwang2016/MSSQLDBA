# This can be used to complement Ola's backup script which doesn't remove aged backup files if the original database is removed or renamed as the time of writing

$VerbosePreference = "Continue"
$path = '' #The path of the folder containing backup files, can be either local path or UNC path
$retention_period = 30 #days

$last_writetime = (Get-Date).AddDays(-$retention_period)

#Remove empty folders and files modified earlier than $last_writetime
#https://stackoverflow.com/questions/28631419/how-to-recursively-remove-all-empty-folders-in-powershell

# Now define a script block that will remove empty folders under
# a root folder, using tail-recursion to ensure that it only
# walks the folder tree once. -Force is used to be able to process
# hidden files/folders as well.
$tailRecursion = {
    param(
        $Path
    )
    foreach ($childDirectory in Get-ChildItem -Force -LiteralPath $Path -Directory) {
        & $tailRecursion -Path $childDirectory.FullName
    }

    #Remove aged files
    Get-ChildItem -Path $Path *.* -Force -File | ?{$_.LastWriteTime -lt $last_writetime} | foreach {Write-Verbose "Removing file '$($_.FullName)'."; Remove-Item -Force $_.FullName}

    #Remove empty folders
    $currentChildren = Get-ChildItem -Force -LiteralPath $Path
    $isEmpty = $currentChildren -eq $null
    if ($isEmpty) {
        Write-Verbose "Removing empty folder '${Path}'."
        Remove-Item -Force -LiteralPath $Path
    }
}

# Lastly invoke the script block and pass in a root path where
# you want it to start. This will remove all empty folders in
# the folder you specify, including empty folders that contain
# nothing but empty folders, including the start folder if that 
# winds up as empty.
& $tailRecursion -Path $path
