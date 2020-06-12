[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $NamePrefix,
    [Parameter(Mandatory = $true)]
    [int] $Number,
    [Parameter(Mandatory = $true,HelpMessage = "Can be any string")]
    [string] $K3sToken,
    [Parameter(Mandatory = $true)]
    [string] $rancherPassword,
    [ValidateScript({(Test-Path "$env:USERPROFILE\.ssh\id_rsa.pub") -or (Test-Path $_)})]
    [string] $PublicKey = "$env:USERPROFILE\.ssh\id_rsa.pub",
    [ValidateScript({(Test-Path $env:USERPROFILE\.ssh\id_rsa) -or (Test-Path $_)})]
    [string] $PrivateKey = "$env:USERPROFILE\.ssh\id_rsa",
    [string[]] $nameServers = @("1.1.1.1","1.0.0.1")
)

Import-Module Hyper-V

$adapter = Get-NetAdapter "vEthernet (Default Switch)"
$wmiAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | ? Description -eq $adapter.ifDesc
$subnet = $wmiAdapter.IpSubnet[0]
$gatewayIp = $wmiAdapter.IPAddress[0]

if (!(Test-Path ".\vms")) {New-Item -ItemType Directory ".\vms" 1>$null}
if (!(Test-Path ".\packer_logs")) {New-Item -ItemType Directory ".\packer_logs" 1>$null}

1..$number | % {
    $vmname = $namePrefix + "{0:00}" -f $_
    $ip = $gatewayIp -replace "\.[0-9]*?$",".$($_+1)"

    Write-Host "Creating $vmname"
    if ($_ -eq 1){
        $masterIp = $ip
        Write-Host "Master IP: $masterIp"
        $cloudconfig = ".\cloud-config.yml"
    } else {
        $cloudconfig = ".\cloud-config-other.yml"
    }

    (Get-Content .\vm.json) `
    -replace "##name##",$vmname `
    -replace "##privatekey##",$PrivateKey -replace "\\","\\" | `
     Set-Content .\$vmname.json

    (Get-Content $cloudconfig) `
        -replace "##name##",$vmname `
        -replace "##sshkey##",(Get-Content $PublicKey) `
        -replace "##k3stoken##",$K3sToken `
        -replace "##ip##",$ip `
        -replace "##subnet##",$subnet `
        -replace "##gateway##",$gatewayIp `
        -replace "##nameservers##",( '"' + ($nameservers -join " ") + '"') `
        -replace "##password##",$password `
        -replace "##masterip##",$masterIp | `
        Set-Content .\$vmname.yml
    $proc = Start-Process ".\packer" -ArgumentList "build -on-error=ask -force `"$vmname.json`"" -NoNewWindow -PassThru -RedirectStandardOutput ".\packer_logs\$vmname.log"
    while (!(Test-Path .\vms\$vmname)){
        Start-Sleep -Seconds 1
    }
    $proc.WaitForExit()
    Remove-Item .\$vmname.json -Force
    Remove-Item .\$vmname.yml -Force
    $vm = Get-ChildItem .\vms\$vmname -Include *.vmcx -Recurse | Import-VM
    $hddPath = $vm | Get-VMHardDiskDrive | select -First 1 -ExpandProperty Path | Split-Path
    New-VHD -Path ($hddPath + "\$vmname`_data01.vhdx") -SizeBytes 50GB -Dynamic 1>$null
    Add-VMHardDiskDrive -VMName $vm.Name -ControllerType SCSI -ControllerNumber 0 -ControllerLocation 1 -Path ($hddPath + "\$vmname`_data01.vhdx")
    $vm | Start-VM
}
if (!(Test-Path $env:USERPROFILE\.kube)) {New-Item -ItemType Directory $env:USERPROFILE\.kube}
(Get-Content .\k3s.yaml) -replace "127.0.0.1",$masterIp | Set-Content $env:USERPROFILE\.kube\config
Remove-Item .\k3s.yaml -Force