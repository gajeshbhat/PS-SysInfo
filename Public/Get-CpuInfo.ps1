function Get-CpuInfo {
    <#
    .SYNOPSIS
        Returns CPU information as a PSCustomObject.
    .DESCRIPTION
        Collects CPU name, physical cores, logical processors, and current usage percent.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-CpuInfo
        Get-CpuInfo | ConvertTo-Json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $platform = Get-PlatformType

    switch ($platform) {
        'Windows' {
            $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
            $usage = ($cpu.LoadPercentage) ?? 0
            [PSCustomObject]@{
                Name              = $cpu.Name.Trim()
                PhysicalCores     = $cpu.NumberOfCores
                LogicalProcessors = $cpu.NumberOfLogicalProcessors
                MaxClockSpeedMHz  = $cpu.MaxClockSpeed
                UsagePercent      = [double]$usage
            }
        }
        'Linux' {
            $cpuInfo = @{}
            $coreCount = 0
            if (Test-Path '/proc/cpuinfo') {
                $lines = Get-Content '/proc/cpuinfo'
                foreach ($line in $lines) {
                    if ($line -match '^model name\s*:\s*(.+)') {
                        $cpuInfo['Name'] = $Matches[1].Trim()
                    }
                    if ($line -match '^cpu cores\s*:\s*(\d+)') {
                        $cpuInfo['PhysicalCores'] = [int]$Matches[1]
                    }
                    if ($line -match '^processor\s*:') {
                        $coreCount++
                    }
                    if ($line -match '^cpu MHz\s*:\s*([\d.]+)') {
                        $cpuInfo['MaxClockSpeedMHz'] = [int][math]::Round([double]$Matches[1])
                    }
                }
            }
            # CPU usage from /proc/stat snapshot
            $usage = 0.0
            try {
                $stat1 = (Get-Content '/proc/stat' | Select-Object -First 1).Trim() -split '\s+'
                Start-Sleep -Milliseconds 200
                $stat2 = (Get-Content '/proc/stat' | Select-Object -First 1).Trim() -split '\s+'
                $idle1 = [long]$stat1[4]; $idle2 = [long]$stat2[4]
                $total1 = ($stat1[1..10] | ForEach-Object { [long]$_ } | Measure-Object -Sum).Sum
                $total2 = ($stat2[1..10] | ForEach-Object { [long]$_ } | Measure-Object -Sum).Sum
                $totalDelta = $total2 - $total1
                $idleDelta = $idle2 - $idle1
                if ($totalDelta -gt 0) {
                    $usage = [math]::Round((1 - $idleDelta / $totalDelta) * 100, 2)
                }
            }
            catch { $usage = 0.0 }

            [PSCustomObject]@{
                Name              = $cpuInfo['Name'] ?? 'Unknown'
                PhysicalCores     = $cpuInfo['PhysicalCores'] ?? 0
                LogicalProcessors = $coreCount
                MaxClockSpeedMHz  = $cpuInfo['MaxClockSpeedMHz'] ?? 0
                UsagePercent      = $usage
            }
        }
        'macOS' {
            $name = (sysctl -n machdep.cpu.brand_string 2>/dev/null) ?? 'Unknown'
            $phys = [int]((sysctl -n hw.physicalcpu 2>/dev/null) ?? 0)
            $logical = [int]((sysctl -n hw.logicalcpu 2>/dev/null) ?? 0)
            $freqHz = [long]((sysctl -n hw.cpufrequency 2>/dev/null) ?? 0)
            $freqMHz = [int]($freqHz / 1000000)
            # macOS has no trivial single-call CPU usage; approximate via ps
            $usage = 0.0
            try {
                $usage = [math]::Round(
                    ((Invoke-PlatformCommand 'ps' @('-A', '-o', '%cpu')) |
                        ForEach-Object { if ($_ -match '^\s*([\d.]+)') { [double]$Matches[1] } } |
                        Measure-Object -Sum).Sum / $logical, 2)
            }
            catch {}

            [PSCustomObject]@{
                Name              = $name.Trim()
                PhysicalCores     = $phys
                LogicalProcessors = $logical
                MaxClockSpeedMHz  = $freqMHz
                UsagePercent      = $usage
            }
        }
        default {
            [PSCustomObject]@{
                Name              = 'Unknown'
                PhysicalCores     = 0
                LogicalProcessors = 0
                MaxClockSpeedMHz  = 0
                UsagePercent      = 0.0
            }
        }
    }
}

