param(
    [string]$Distro = "Debian",
    [switch]$MockWifi
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Write-Host "[Windra] Building/running shell in WSL distro: $Distro"
Write-Host "[Windra] Windows source: $root"

$linuxRoot = (& wsl.exe -d $Distro -- wslpath -a -u $root).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($linuxRoot)) {
    throw "Windra could not convert the project path for WSL distro '$Distro'."
}

Write-Host "[Windra] WSL source: $linuxRoot"

$linuxArgs = @()
if ($MockWifi) {
    $linuxArgs += "--mock-wifi"
}

$command = @'
set -e
cd "$1"
shift
if ! command -v cmake >/dev/null 2>&1; then
  echo "[Windra] cmake is missing in WSL. Run: ./tools/bootstrap-debian.sh" >&2
  exit 127
fi
exec bash tools/dev-run.sh "$@"
'@

& wsl.exe -d $Distro -- bash -lc $command bash $linuxRoot @linuxArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
