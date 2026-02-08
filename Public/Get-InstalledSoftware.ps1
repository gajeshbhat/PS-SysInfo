function Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Returns a list of installed software as an array of PSCustomObjects.
    .DESCRIPTION
        Collects software name, version, and vendor/source.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-InstalledSoftware
        Get-InstalledSoftware | ConvertTo-Json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $platform = Get-PlatformType
    $software = @()

    switch ($platform) {
        'Windows' {
            $regPaths = @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
            foreach ($path in $regPaths) {
                Get-ItemProperty $path -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName } |
                    ForEach-Object {
                        $software += [PSCustomObject]@{
                            Name    = $_.DisplayName
                            Version = $_.DisplayVersion ?? 'Unknown'
                            Source  = $_.Publisher ?? 'Unknown'
                        }
                    }
            }
        }
        'Linux' {
            # Try dpkg (Debian/Ubuntu), then rpm (RHEL/Fedora), then pacman (Arch)
            $dpkg = Invoke-PlatformCommand 'dpkg-query' @('-W', '-f', '${Package}\t${Version}\n') 2>/dev/null
            if ($dpkg) {
                foreach ($line in $dpkg) {
                    $parts = $line -split '\t', 2
                    if ($parts.Count -ge 2) {
                        $software += [PSCustomObject]@{
                            Name    = $parts[0]
                            Version = $parts[1]
                            Source  = 'dpkg'
                        }
                    }
                }
            }
            else {
                $rpm = Invoke-PlatformCommand 'rpm' @('-qa', '--queryformat', '%{NAME}\t%{VERSION}\n') 2>/dev/null
                if ($rpm) {
                    foreach ($line in $rpm) {
                        $parts = $line -split '\t', 2
                        if ($parts.Count -ge 2) {
                            $software += [PSCustomObject]@{
                                Name    = $parts[0]
                                Version = $parts[1]
                                Source  = 'rpm'
                            }
                        }
                    }
                }
            }
        }
        'macOS' {
            $brewList = Invoke-PlatformCommand 'brew' @('list', '--versions') 2>/dev/null
            if ($brewList) {
                foreach ($line in $brewList) {
                    $parts = $line -split '\s+', 2
                    $software += [PSCustomObject]@{
                        Name    = $parts[0]
                        Version = if ($parts.Count -ge 2) { $parts[1] } else { 'Unknown' }
                        Source  = 'brew'
                    }
                }
            }
            # Also check /Applications
            $apps = Get-ChildItem '/Applications' -Filter '*.app' -ErrorAction SilentlyContinue
            foreach ($app in $apps) {
                $software += [PSCustomObject]@{
                    Name    = $app.BaseName
                    Version = 'Unknown'
                    Source  = 'Applications'
                }
            }
        }
    }

    if ($software.Count -eq 0) {
        $software += [PSCustomObject]@{ Name = 'N/A'; Version = 'N/A'; Source = 'N/A' }
    }
    $software | Sort-Object Name
}

