BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-OsInfo.ps1"
}

Describe 'Get-OsInfo' {
    Context 'On any platform' {
        It 'Returns a PSCustomObject' {
            $result = Get-OsInfo
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Has all expected properties' {
            $result = Get-OsInfo
            $result.PSObject.Properties.Name | Should -Contain 'Name'
            $result.PSObject.Properties.Name | Should -Contain 'Version'
            $result.PSObject.Properties.Name | Should -Contain 'Build'
            $result.PSObject.Properties.Name | Should -Contain 'Architecture'
            $result.PSObject.Properties.Name | Should -Contain 'Hostname'
            $result.PSObject.Properties.Name | Should -Contain 'UptimeHours'
        }

        It 'Name is a non-empty string' {
            $result = Get-OsInfo
            $result.Name | Should -Not -BeNullOrEmpty
        }

        It 'UptimeHours is a non-negative number' {
            $result = Get-OsInfo
            $result.UptimeHours | Should -BeGreaterOrEqual 0
        }
    }

    Context 'Mocked as Linux' {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Test-Path { return $true }
            Mock Get-Content {
                if ($Path -eq '/etc/os-release' -or $args -contains '/etc/os-release') {
                    return @(
                        'PRETTY_NAME="Ubuntu 22.04 LTS"'
                        'VERSION_ID="22.04"'
                    )
                }
                if ($Path -eq '/proc/uptime' -or $args -contains '/proc/uptime') {
                    return '36000.50 72000.10'
                }
            }
        }

        It 'Returns Linux OS info with mocked data' {
            $result = Get-OsInfo
            $result.Name | Should -Be 'Ubuntu 22.04 LTS'
            $result.Version | Should -Be '22.04'
            $result.UptimeHours | Should -BeGreaterOrEqual 0
        }
    }
}

