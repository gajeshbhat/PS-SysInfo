BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-CpuInfo.ps1"
}

Describe 'Get-CpuInfo' {
    Context 'On any platform' {
        It 'Returns a PSCustomObject' {
            $result = Get-CpuInfo
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Has all expected properties' {
            $result = Get-CpuInfo
            $expected = @('Name', 'PhysicalCores', 'LogicalProcessors', 'MaxClockSpeedMHz', 'UsagePercent')
            foreach ($prop in $expected) {
                $result.PSObject.Properties.Name | Should -Contain $prop
            }
        }

        It 'LogicalProcessors is greater than 0' {
            $result = Get-CpuInfo
            $result.LogicalProcessors | Should -BeGreaterThan 0
        }

        It 'UsagePercent is between 0 and 100' {
            $result = Get-CpuInfo
            $result.UsagePercent | Should -BeGreaterOrEqual 0
            $result.UsagePercent | Should -BeLessOrEqual 100
        }
    }

    Context 'Mocked as Linux' {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Test-Path { return $true }
            Mock Get-Content {
                param($Path)
                if ($Path -eq '/proc/cpuinfo' -or "$args" -match 'cpuinfo') {
                    return @(
                        'processor	: 0'
                        'model name	: Test CPU @ 3.50GHz'
                        'cpu cores	: 4'
                        'cpu MHz		: 3500.000'
                        'processor	: 1'
                    )
                }
                if ($Path -eq '/proc/stat' -or "$args" -match 'stat') {
                    return @('cpu  1000 200 300 5000 50 0 0 0 0 0')
                }
            }
            Mock Start-Sleep {}
        }

        It 'Parses /proc/cpuinfo correctly' {
            $result = Get-CpuInfo
            $result.Name | Should -Be 'Test CPU @ 3.50GHz'
            $result.PhysicalCores | Should -Be 4
            $result.LogicalProcessors | Should -Be 2
            $result.MaxClockSpeedMHz | Should -Be 3500
        }
    }
}

