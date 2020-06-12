Import-Module Hyper-V
$vmFolders = Get-ChildItem ".\vms" -Directory
foreach ($vmFolder in $vmFolders) {
    Get-VM $vmFolder.Name | Stop-VM -TurnOff -Passthru | Remove-VM -Force
    Remove-Item $vmFolder.FullName -Recurse -Force
}