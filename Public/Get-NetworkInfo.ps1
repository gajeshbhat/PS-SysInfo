function Get-NetworkInfo {
    <#
    .SYNOPSIS
        Returns network adapter information as an array of PSCustomObjects.
    .DESCRIPTION
        Collects adapter name, MAC address, IPv4/IPv6 addresses, and status.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-NetworkInfo
        Get-NetworkInfo | ConvertTo-Json -Depth 3
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $platform = Get-PlatformType

    switch ($platform) {
        'Windows' {
            Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | ForEach-Object {
                [PSCustomObject]@{
                    Name       = $_.Description
                    MacAddress = $_.MACAddress
                    IPv4       = @($_.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' })
                    IPv6       = @($_.IPAddress | Where-Object { $_ -match ':' })
                    Status     = 'Up'
                }
            }
        }
        'Linux' {
            $adapters = @()
            $ipOutput = ip -o addr show 2>/dev/null
            if ($ipOutput) {
                $grouped = @{}
                foreach ($line in $ipOutput) {
                    if ($line -match '^\d+:\s+(\S+)\s+inet6?\s+(\S+)') {
                        $iface = $Matches[1]
                        $addr = $Matches[2] -replace '/\d+$', ''
                        if (-not $grouped[$iface]) { $grouped[$iface] = @{ IPv4 = @(); IPv6 = @() } }
                        if ($addr -match ':') { $grouped[$iface].IPv6 += $addr }
                        else { $grouped[$iface].IPv4 += $addr }
                    }
                }
                foreach ($iface in $grouped.Keys) {
                    if ($iface -eq 'lo') { continue }
                    $mac = ''
                    $macLine = ip link show $iface 2>/dev/null | Select-String 'link/ether'
                    if ($macLine -and $macLine -match 'link/ether\s+([\w:]+)') {
                        $mac = $Matches[1]
                    }
                    $adapters += [PSCustomObject]@{
                        Name       = $iface
                        MacAddress = $mac
                        IPv4       = @($grouped[$iface].IPv4)
                        IPv6       = @($grouped[$iface].IPv6)
                        Status     = 'Up'
                    }
                }
            }
            if ($adapters.Count -eq 0) {
                $adapters += [PSCustomObject]@{
                    Name = 'Unknown'; MacAddress = ''; IPv4 = @(); IPv6 = @(); Status = 'Unknown'
                }
            }
            $adapters
        }
        'macOS' {
            $adapters = @()
            $ifconfigOutput = ifconfig 2>/dev/null
            if ($ifconfigOutput) {
                $currentIface = $null
                $currentMac = ''
                $currentIPv4 = @()
                $currentIPv6 = @()
                foreach ($line in $ifconfigOutput) {
                    if ($line -match '^(\S+):\s+flags=') {
                        # Save previous interface
                        if ($currentIface -and $currentIface -ne 'lo0') {
                            $adapters += [PSCustomObject]@{
                                Name       = $currentIface
                                MacAddress = $currentMac
                                IPv4       = @($currentIPv4)
                                IPv6       = @($currentIPv6)
                                Status     = 'Up'
                            }
                        }
                        $currentIface = $Matches[1]
                        $currentMac = ''
                        $currentIPv4 = @()
                        $currentIPv6 = @()
                    }
                    elseif ($line -match '\s+ether\s+([\w:]+)') {
                        $currentMac = $Matches[1]
                    }
                    elseif ($line -match '\s+inet\s+(\d+\.\d+\.\d+\.\d+)') {
                        $currentIPv4 += $Matches[1]
                    }
                    elseif ($line -match '\s+inet6\s+([^\s%]+)') {
                        $currentIPv6 += $Matches[1]
                    }
                }
                # Save last interface
                if ($currentIface -and $currentIface -ne 'lo0') {
                    $adapters += [PSCustomObject]@{
                        Name       = $currentIface
                        MacAddress = $currentMac
                        IPv4       = @($currentIPv4)
                        IPv6       = @($currentIPv6)
                        Status     = 'Up'
                    }
                }
            }
            if ($adapters.Count -eq 0) {
                $adapters += [PSCustomObject]@{
                    Name = 'Unknown'; MacAddress = ''; IPv4 = @(); IPv6 = @(); Status = 'Unknown'
                }
            }
            $adapters
        }
        default {
            [PSCustomObject]@{
                Name = 'Unknown'; MacAddress = ''; IPv4 = @(); IPv6 = @(); Status = 'Unknown'
            }
        }
    }
}

