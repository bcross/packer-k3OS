[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $Hostname
)
Write-Host "Waiting to connect to the cluster..."
.\kubectl version *>$null
while (!$?){
    Start-Sleep -seconds 5
    .\kubectl version *>$null
}

.\helm repo add jetstack https://charts.jetstack.io
.\helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
.\helm repo update
.\kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml
.\kubectl create namespace cert-manager
.\helm install cert-manager jetstack/cert-manager --namespace cert-manager --wait
.\kubectl create namespace cattle-system
.\helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=$hostname
.\kubectl -n cattle-system rollout status deploy/rancher
.\kubectl expose deployment -n cattle-system rancher --type=LoadBalancer --name=rancher-lb