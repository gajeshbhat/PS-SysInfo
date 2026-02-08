function Get-DiskInfo {
    <#
    .SYNOPSIS
        Returns disk/volume information as an array of PSCustomObjects.
    .DESCRIPTION
        Collects mount point, filesystem, total/used/free space and usage percent for each volume.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-DiskInfo
        Get-DiskInfo | ConvertTo-Json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $platform = Get-PlatformType

    switch ($platform) {
        'Windows' {
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
                $totalGB = [math]::Round($_.Size / 1GB, 2)
                $freeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                $usedGB = [math]::Round($totalGB - $freeGB, 2)
                $pct = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }
                [PSCustomObject]@{
                    Mount        = $_.DeviceID
                    FileSystem   = $_.FileSystem
                    TotalGB      = $totalGB
                    UsedGB       = $usedGB
                    FreeGB       = $freeGB
                    UsagePercent = $pct
                }
            }
        }
        { $_ -in 'Linux', 'macOS' } {
            $dfOutput = df -P -T 2>/dev/null
            if (-not $dfOutput) { $dfOutput = df -P 2>/dev/null }
            if ($dfOutput) {
                $dfOutput | Select-Object -Skip 1 | ForEach-Object {
                    $parts = $_ -split '\s+'
                    # df -P -T: Device Type Blocks Used Available Capacity Mount
                    # df -P:    Device Blocks Used Available Capacity Mount
                    if ($parts.Count -ge 7) {
                        $fs = $parts[1]; $totalKB = [long]$parts[2]; $usedKB = [long]$parts[3]
                        $freeKB = [long]$parts[4]; $mount = $parts[6]
                    }
                    elseif ($parts.Count -ge 6) {
                        $fs = 'Unknown'; $totalKB = [long]$parts[1]; $usedKB = [long]$parts[2]
                        $freeKB = [long]$parts[3]; $mount = $parts[5]
                    }
                    else { return }

                    # Skip pseudo filesystems
                    if ($mount -match '^/(dev|proc|sys|run|snap)' -and $mount -ne '/') { return }

                    $totalGB = [math]::Round($totalKB / 1MB, 2)
                    $usedGB = [math]::Round($usedKB / 1MB, 2)
                    $freeGB = [math]::Round($freeKB / 1MB, 2)
                    $pct = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }
                    [PSCustomObject]@{
                        Mount        = $mount
                        FileSystem   = $fs
                        TotalGB      = $totalGB
                        UsedGB       = $usedGB
                        FreeGB       = $freeGB
                        UsagePercent = $pct
                    }
                }
            }
        }
        default {
            [PSCustomObject]@{
                Mount = 'Unknown'; FileSystem = 'Unknown'
                TotalGB = 0; UsedGB = 0; FreeGB = 0; UsagePercent = 0
            }
        }
    }
}

