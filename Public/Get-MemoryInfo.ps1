function Get-MemoryInfo {
    <#
    .SYNOPSIS
        Returns memory (RAM) information as a PSCustomObject.
    .DESCRIPTION
        Collects total, used, free RAM and usage percentage.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-MemoryInfo
        Get-MemoryInfo | ConvertTo-Json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $platform = Get-PlatformType

    switch ($platform) {
        'Windows' {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            $freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            $usedGB = [math]::Round($totalGB - $freeGB, 2)
            $pct = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }
            [PSCustomObject]@{
                TotalGB      = $totalGB
                UsedGB       = $usedGB
                FreeGB       = $freeGB
                UsagePercent = $pct
            }
        }
        'Linux' {
            $mem = @{}
            if (Test-Path '/proc/meminfo') {
                Get-Content '/proc/meminfo' | ForEach-Object {
                    if ($_ -match '^(\w+):\s+(\d+)') {
                        $mem[$Matches[1]] = [long]$Matches[2]
                    }
                }
            }
            $totalKB = $mem['MemTotal'] ?? 0
            $availKB = $mem['MemAvailable'] ?? 0
            $totalGB = [math]::Round($totalKB / 1MB, 2)
            $freeGB = [math]::Round($availKB / 1MB, 2)
            $usedGB = [math]::Round($totalGB - $freeGB, 2)
            $pct = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }
            [PSCustomObject]@{
                TotalGB      = $totalGB
                UsedGB       = $usedGB
                FreeGB       = $freeGB
                UsagePercent = $pct
            }
        }
        'macOS' {
            $totalBytes = [long]((sysctl -n hw.memsize 2>/dev/null) ?? 0)
            $totalGB = [math]::Round($totalBytes / 1GB, 2)
            # vm_stat gives pages; page size is typically 4096 or 16384
            $pageSize = [long]((sysctl -n hw.pagesize 2>/dev/null) ?? 4096)
            $freeGB = 0.0
            try {
                $vmstat = vm_stat 2>/dev/null
                $freePages = 0
                $vmstat | ForEach-Object {
                    if ($_ -match 'Pages free:\s+(\d+)') { $freePages += [long]$Matches[1] }
                    if ($_ -match 'Pages inactive:\s+(\d+)') { $freePages += [long]$Matches[1] }
                }
                $freeGB = [math]::Round(($freePages * $pageSize) / 1GB, 2)
            }
            catch {}
            $usedGB = [math]::Round($totalGB - $freeGB, 2)
            $pct = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 2) } else { 0 }
            [PSCustomObject]@{
                TotalGB      = $totalGB
                UsedGB       = $usedGB
                FreeGB       = $freeGB
                UsagePercent = $pct
            }
        }
        default {
            [PSCustomObject]@{
                TotalGB      = 0
                UsedGB       = 0
                FreeGB       = 0
                UsagePercent = 0
            }
        }
    }
}

