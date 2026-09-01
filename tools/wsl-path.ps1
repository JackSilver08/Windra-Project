function ConvertTo-WindraWslPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )

    $fullPath = [System.IO.Path]::GetFullPath($WindowsPath)

    if ($fullPath -notmatch '^([A-Za-z]):(?:\\(.*))?$') {
        throw "Windra currently expects the project to live on a Windows drive path such as C:\\Windra-Project. Received: $fullPath"
    }

    $drive = $Matches[1].ToLowerInvariant()
    $tail = $Matches[2]

    if ([string]::IsNullOrEmpty($tail)) {
        return "/mnt/$drive"
    }

    $tail = $tail.Replace('\', '/')
    return "/mnt/$drive/$tail"
}
