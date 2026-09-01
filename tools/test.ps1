param(
    [string]$Distro = "Debian"
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Write-Host "[Windra] Running tests in WSL distro: $Distro"
Write-Host "[Windra] Windows source: $root"

# Let wslpath do the Windows -> Linux path conversion. Passing the path as a
# normal argv item avoids fragile nested PowerShell/Bash quote escaping.
$linuxRoot = (& wsl.exe -d $Distro -- wslpath -a -u $root).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($linuxRoot)) {
    throw "Windra could not convert the project path for WSL distro '$Distro'."
}

Write-Host "[Windra] WSL source: $linuxRoot"

$command = @'
set -e
cd "$1"
if ! command -v cmake >/dev/null 2>&1; then
  echo "[Windra] cmake is missing in WSL. Run: ./tools/bootstrap-debian.sh" >&2
  exit 127
fi
exec bash tools/test.sh
'@

& wsl.exe -d $Distro -- bash -lc $command bash $linuxRoot
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
