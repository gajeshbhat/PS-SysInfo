BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-BatteryInfo.ps1"
}

Describe 'Get-BatteryInfo' {
    Context 'On any platform' {
        It 'Returns a PSCustomObject' {
            $result = Get-BatteryInfo
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Has all expected properties' {
            $result = Get-BatteryInfo
            $expected = @('Present', 'ChargePercent', 'IsCharging', 'Status')
            foreach ($prop in $expected) {
                $result.PSObject.Properties.Name | Should -Contain $prop
            }
        }
    }

    Context 'Mocked Linux with battery' {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Test-Path { return $true }
            Mock Get-Content {
                param($Path)
                if ($Path -match 'capacity') { return '85' }
                if ($Path -match 'status') { return 'Charging' }
                return ''
            }
        }

        It 'Returns battery present with charge' {
            $result = Get-BatteryInfo
            $result.Present | Should -BeTrue
            $result.ChargePercent | Should -Be 85
            $result.IsCharging | Should -BeTrue
            $result.Status | Should -Be 'Charging'
        }
    }

    Context 'Mocked Linux without battery' {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Test-Path { return $false }
        }

        It 'Returns not present' {
            $result = Get-BatteryInfo
            $result.Present | Should -BeFalse
            $result.Status | Should -Be 'No battery'
        }
    }
}

