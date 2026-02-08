BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-MemoryInfo.ps1"
}

Describe 'Get-MemoryInfo' {
    Context 'On any platform' {
        It 'Returns a PSCustomObject' {
            $result = Get-MemoryInfo
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Has all expected properties' {
            $result = Get-MemoryInfo
            $expected = @('TotalGB', 'UsedGB', 'FreeGB', 'UsagePercent')
            foreach ($prop in $expected) {
                $result.PSObject.Properties.Name | Should -Contain $prop
            }
        }

        It 'TotalGB is greater than 0' {
            $result = Get-MemoryInfo
            $result.TotalGB | Should -BeGreaterThan 0
        }

        It 'UsagePercent is between 0 and 100' {
            $result = Get-MemoryInfo
            $result.UsagePercent | Should -BeGreaterOrEqual 0
            $result.UsagePercent | Should -BeLessOrEqual 100
        }
    }

    Context 'Mocked as Linux' {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Test-Path { return $true }
            Mock Get-Content {
                return @(
                    'MemTotal:       16384000 kB'
                    'MemFree:         4096000 kB'
                    'MemAvailable:    8192000 kB'
                )
            }
        }

        It 'Parses /proc/meminfo correctly' {
            $result = Get-MemoryInfo
            $result.TotalGB | Should -BeGreaterThan 15
            $result.TotalGB | Should -BeLessThan 17
            $result.FreeGB | Should -BeGreaterThan 7
            $result.UsagePercent | Should -BeGreaterThan 0
        }
    }
}

