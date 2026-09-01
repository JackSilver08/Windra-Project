param(
    [string]$Distro = "Debian"
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$escapedRoot = $root.Replace("'", "'\"'\"'")

Write-Host "[Windra] Chạy test trong WSL distro: $Distro"
Write-Host "[Windra] Source Windows: $root"

$command = @"
set -e
ROOT=`$(wslpath -u '$escapedRoot')
cd "`$ROOT"
if ! command -v cmake >/dev/null 2>&1; then
  echo '[Windra] Thiếu cmake trong WSL. Chạy: ./tools/bootstrap-debian.sh' >&2
  exit 127
fi
bash tools/test.sh
"@

wsl.exe -d $Distro -- bash -lc $command
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
