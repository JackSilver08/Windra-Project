param(
    [string]$Distro = "Debian",
    [switch]$MockWifi
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$escapedRoot = $root.Replace("'", "'\"'\"'")
$mockArg = if ($MockWifi) { "--mock-wifi" } else { "" }

Write-Host "[Windra] Build/chạy shell trong WSL distro: $Distro"
Write-Host "[Windra] Source Windows: $root"

$command = @"
set -e
ROOT=`$(wslpath -u '$escapedRoot')
cd "`$ROOT"
if ! command -v cmake >/dev/null 2>&1; then
  echo '[Windra] Thiếu cmake trong WSL. Chạy: ./tools/bootstrap-debian.sh' >&2
  exit 127
fi
bash tools/dev-run.sh $mockArg
"@

wsl.exe -d $Distro -- bash -lc $command
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
