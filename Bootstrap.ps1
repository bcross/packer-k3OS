[CmdletBinding()]
param (
    [switch] $Force
)
Add-Type -AssemblyName System.IO.Compression.FileSystem

#Get Packer
if (!(Test-Path ".\packer.exe") -or $Force) {
    Write-Host "Getting Packer"
    $rootpath = "https://releases.hashicorp.com"
    $versions = Invoke-WebRequest -Method GET "$rootpath/packer" -UseBasicParsing
    $oses = Invoke-WebRequest -Method GET ($rootpath + $versions.Links[1].href) -UseBasicParsing
    (New-Object System.Net.WebClient).DownloadFile(($rootpath + ($oses.Links | Where-Object {$_.href -match "windows_$env:PROCESSOR_ARCHITECTURE"}).href),"$PSScriptRoot\packer.zip")
    $zip = (Get-Item -Path ".\packer.zip").FullName
    Remove-Item .\packer.exe -Force 2>$null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, (Split-Path $zip))
    Remove-Item $zip -Force
}

#Get k3OS
if (!(Test-Path ".\k3os-amd64.iso") -or $Force) {
    Write-Host "Getting k3OS"
    $k3osRelease = Invoke-RestMethod -Method Get https://api.github.com/repos/rancher/k3os/releases/latest
    $k3osDownloadUrl = $k3osRelease.assets | ? name -eq "k3os-amd64.iso" | select -ExpandProperty browser_download_url
    $k3osHashUrl = $k3osRelease.assets | ? name -eq "sha256sum-amd64.txt" | select -ExpandProperty browser_download_url
    Remove-Item .\k3os-amd64.iso -Force 2>$null
    (New-Object System.Net.WebClient).DownloadFile($k3osDownloadUrl, "$PSScriptRoot\k3os-amd64.iso")
    (New-Object System.Net.WebClient).DownloadFile($k3osHashUrl, "$PSScriptRoot\sha256sum-amd64.txt")
    (Get-Content .\sha256sum-amd64.txt | Select-String k3os-amd64.iso) -match "(.*)\s+.*" 1>$null
    $k3osHash = $matches[1] -replace "\s+",""
    (Get-Content .\vm.json) -replace '"iso_checksum": ".*"',"`"iso_checksum`": `"sha256:$k3oshash`"" | Set-Content .\vm.json
    Remove-Item .\sha256sum-amd64.txt -Force
}

#Get Helm
if (!(Test-Path ".\helm.exe") -or $Force) {
    Write-Host "Getting Helm"
    $helmReleases = Invoke-RestMethod -Method Get https://api.github.com/repos/helm/helm/releases
    $helmVersion = $helmReleases | ? prerelease -eq $false | sort -Descending tag_name | select -First 1 -ExpandProperty tag_name
    (New-Object System.Net.WebClient).DownloadFile("https://get.helm.sh/helm-$helmVersion-windows-amd64.zip", "$PSScriptRoot\helm.zip")
    $zip = Get-Item .\helm.zip
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, (Split-Path $zip))
    Move-Item ".\windows-amd64\helm.exe" ".\helm.exe" -Force
    Remove-Item windows-amd64 -Recurse -Force
    Remove-Item $zip -Force
}

#Get Kubectl
if (!(Test-Path ".\kubectl.exe") -or $Force) {
    Write-Host "Getting Kubectl"
    $kubectlRelease = (Invoke-RestMethod -Method Get https://storage.googleapis.com/kubernetes-release/release/stable.txt) -replace "\s+",""
    Remove-Item .\kubectl.exe -Force 2>$null
    (New-Object System.Net.WebClient).DownloadFile("https://storage.googleapis.com/kubernetes-release/release/$kubectlRelease/bin/windows/amd64/kubectl.exe", "$PSScriptRoot\kubectl.exe")
}