param(
    [string]$Distro = "Debian",
    [switch]$MockWifi
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "wsl-path.ps1")

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$linuxRoot = ConvertTo-WindraWslPath -WindowsPath $root
$linuxScript = "$linuxRoot/tools/dev-run.sh"

Write-Host "[Windra] Building/running shell in WSL distro: $Distro"
Write-Host "[Windra] Windows source: $root"
Write-Host "[Windra] WSL source: $linuxRoot"

$wslArgs = @("-d", $Distro, "--", "bash", $linuxScript)
if ($MockWifi) {
    $wslArgs += "--mock-wifi"
}

# Pass every item as an argument. Do not compose a bash command string here;
# paths containing spaces must survive the PowerShell -> wsl.exe boundary.
& wsl.exe @wslArgs
if ($LASTEXITCODE -ne 0) {
    if ($LASTEXITCODE -eq 127) {
        Write-Host "[Windra] A required Linux tool is missing. Run .\tools\bootstrap-wsl.ps1 first." -ForegroundColor Yellow
    }
    exit $LASTEXITCODE
}
