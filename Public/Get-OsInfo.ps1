function Get-OsInfo {
    <#
    .SYNOPSIS
        Returns operating system information as a PSCustomObject.
    .DESCRIPTION
        Collects OS name, version, architecture, hostname, and uptime.
        Works cross-platform on Windows, Linux, and macOS.
        Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-OsInfo
        Get-OsInfo | ConvertTo-Json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $platform = Get-PlatformType

    switch ($platform) {
        'Windows' {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            [PSCustomObject]@{
                Name         = $os.Caption.Trim()
                Version      = $os.Version
                Build        = $os.BuildNumber
                Architecture = $os.OSArchitecture
                Hostname     = $env:COMPUTERNAME
                UptimeHours  = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 2)
            }
        }
        'Linux' {
            $osRelease = @{}
            if (Test-Path '/etc/os-release') {
                Get-Content '/etc/os-release' | ForEach-Object {
                    if ($_ -match '^(\w+)=(.*)$') {
                        $osRelease[$Matches[1]] = $Matches[2].Trim('"')
                    }
                }
            }
            $uptimeSeconds = 0
            if (Test-Path '/proc/uptime') {
                $uptimeSeconds = [double]((Get-Content '/proc/uptime').Split(' ')[0])
            }
            [PSCustomObject]@{
                Name         = $osRelease['PRETTY_NAME'] ?? 'Linux'
                Version      = $osRelease['VERSION_ID'] ?? 'Unknown'
                Build        = (uname -r 2>/dev/null) ?? 'Unknown'
                Architecture = (uname -m 2>/dev/null) ?? 'Unknown'
                Hostname     = (hostname 2>/dev/null) ?? 'Unknown'
                UptimeHours  = [math]::Round($uptimeSeconds / 3600, 2)
            }
        }
        'macOS' {
            $productName = (Invoke-PlatformCommand 'sw_vers' @('-productName')) ?? 'macOS'
            $productVersion = (Invoke-PlatformCommand 'sw_vers' @('-productVersion')) ?? 'Unknown'
            $buildVersion = (Invoke-PlatformCommand 'sw_vers' @('-buildVersion')) ?? 'Unknown'
            $arch = (uname -m 2>/dev/null) ?? 'Unknown'
            $hostName = (hostname 2>/dev/null) ?? 'Unknown'
            $bootTime = (sysctl -n kern.boottime 2>/dev/null)
            $uptimeHours = 0
            if ($bootTime -match 'sec = (\d+)') {
                $uptimeHours = [math]::Round(((Get-Date) - ([DateTimeOffset]::FromUnixTimeSeconds([long]$Matches[1])).DateTime).TotalHours, 2)
            }
            [PSCustomObject]@{
                Name         = "$productName $productVersion"
                Version      = $productVersion
                Build        = $buildVersion
                Architecture = $arch
                Hostname     = $hostName
                UptimeHours  = $uptimeHours
            }
        }
        default {
            [PSCustomObject]@{
                Name         = 'Unknown'
                Version      = 'Unknown'
                Build        = 'Unknown'
                Architecture = 'Unknown'
                Hostname     = 'Unknown'
                UptimeHours  = 0
            }
        }
    }
}

