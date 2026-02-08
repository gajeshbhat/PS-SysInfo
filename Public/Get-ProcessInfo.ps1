function Get-ProcessInfo {
    <#
    .SYNOPSIS
        Returns process summary information as a PSCustomObject.
    .DESCRIPTION
        Collects total process count and top 5 processes by CPU usage.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-ProcessInfo
        Get-ProcessInfo | ConvertTo-Json -Depth 3
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [int]$TopN = 5
    )

    $processes = Get-Process -ErrorAction SilentlyContinue
    $total = @($processes).Count

    $topByCpu = @($processes |
        Sort-Object CPU -Descending |
        Select-Object -First $TopN |
        ForEach-Object {
            [PSCustomObject]@{
                Name      = $_.ProcessName
                Id        = $_.Id
                CpuSeconds = [math]::Round($_.CPU, 2)
                MemoryMB  = [math]::Round($_.WorkingSet64 / 1MB, 2)
            }
        })

    $topByMem = @($processes |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First $TopN |
        ForEach-Object {
            [PSCustomObject]@{
                Name      = $_.ProcessName
                Id        = $_.Id
                CpuSeconds = [math]::Round($_.CPU, 2)
                MemoryMB  = [math]::Round($_.WorkingSet64 / 1MB, 2)
            }
        })

    [PSCustomObject]@{
        TotalCount  = $total
        TopByCpu    = $topByCpu
        TopByMemory = $topByMem
    }
}

