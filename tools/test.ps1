param(
    [string]$Distro = "Debian"
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "wsl-path.ps1")

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$linuxRoot = ConvertTo-WindraWslPath -WindowsPath $root
$linuxScript = "$linuxRoot/tools/test.sh"

Write-Host "[Windra] Running tests in WSL distro: $Distro"
Write-Host "[Windra] Windows source: $root"
Write-Host "[Windra] WSL source: $linuxRoot"

# Invoke the Linux script as argv instead of building a nested shell command.
# This keeps spaces in paths intact and avoids PowerShell/Bash quote escaping.
& wsl.exe -d $Distro -- bash $linuxScript
if ($LASTEXITCODE -ne 0) {
    if ($LASTEXITCODE -eq 127) {
        Write-Host "[Windra] A required Linux tool is missing. Run .\tools\bootstrap-wsl.ps1 first." -ForegroundColor Yellow
    }
    exit $LASTEXITCODE
}
