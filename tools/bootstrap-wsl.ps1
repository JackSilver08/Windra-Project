param(
    [string]$Distro = "Debian"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "wsl-path.ps1")

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$linuxRoot = ConvertTo-WindraWslPath -WindowsPath $root
$linuxScript = "$linuxRoot/tools/bootstrap-debian.sh"

Write-Host "[Windra] Bootstrapping WSL distro: $Distro"
Write-Host "[Windra] Windows source: $root"
Write-Host "[Windra] WSL source: $linuxRoot"

& wsl.exe -d $Distro -- bash $linuxScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
