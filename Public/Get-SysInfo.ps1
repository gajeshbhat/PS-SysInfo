function Get-SysInfo {
    <#
    .SYNOPSIS
        Returns comprehensive system information as a PSCustomObject.
    .DESCRIPTION
        Aggregates CPU, Memory, Disk, Network, OS, Processes, GPU, Battery,
        and Installed Software into a single object. Use -Section to select
        specific sections and -Property to filter properties within sections.
        Pipe to ConvertTo-Json -Depth 5 for JSON output.
    .PARAMETER Section
        One or more sections to include. Valid values: Cpu, Memory, Disk,
        Network, Os, Processes, Gpu, Battery, Software. Defaults to all.
    .PARAMETER Property
        One or more property names to include within each section.
        Only applies to sections that return single objects (not arrays).
    .EXAMPLE
        Get-SysInfo | ConvertTo-Json -Depth 5
    .EXAMPLE
        Get-SysInfo -Section Cpu, Memory
    .EXAMPLE
        Get-SysInfo -Section Os -Property Name, Version
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [ValidateSet('Cpu', 'Memory', 'Disk', 'Network', 'Os', 'Processes', 'Gpu', 'Battery', 'Software')]
        [string[]]$Section,

        [string[]]$Property
    )

    $allSections = @('Cpu', 'Memory', 'Disk', 'Network', 'Os', 'Processes', 'Gpu', 'Battery', 'Software')
    $selected = if ($Section) { $Section } else { $allSections }

    $sectionMap = @{
        'Cpu'       = { Get-CpuInfo }
        'Memory'    = { Get-MemoryInfo }
        'Disk'      = { Get-DiskInfo }
        'Network'   = { Get-NetworkInfo }
        'Os'        = { Get-OsInfo }
        'Processes' = { Get-ProcessInfo }
        'Gpu'       = { Get-GpuInfo }
        'Battery'   = { Get-BatteryInfo }
        'Software'  = { Get-InstalledSoftware }
    }

    $result = [ordered]@{
        Timestamp = (Get-Date).ToUniversalTime().ToString('o')
        Platform  = Get-PlatformType
    }

    foreach ($sec in $selected) {
        $data = & $sectionMap[$sec]

        # Apply property filter to single objects (not arrays)
        if ($Property -and $data -isnot [System.Array] -and $data -is [PSCustomObject]) {
            $data = $data | Select-Object -Property $Property -ErrorAction SilentlyContinue
        }

        $result[$sec] = $data
    }

    [PSCustomObject]$result
}

