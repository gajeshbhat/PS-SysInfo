BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-DiskInfo.ps1"
}

Describe 'Get-DiskInfo' {
    Context 'On any platform' {
        It 'Returns one or more objects' {
            $result = @(Get-DiskInfo)
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Each object has expected properties' {
            $result = @(Get-DiskInfo)
            $expected = @('Mount', 'FileSystem', 'TotalGB', 'UsedGB', 'FreeGB', 'UsagePercent')
            foreach ($disk in $result) {
                foreach ($prop in $expected) {
                    $disk.PSObject.Properties.Name | Should -Contain $prop
                }
            }
        }

        It 'TotalGB is greater than 0 for at least one disk' {
            $result = @(Get-DiskInfo)
            ($result | Where-Object { $_.TotalGB -gt 0 }).Count | Should -BeGreaterThan 0
        }
    }

    Context 'Mocked as Linux' {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
        }

        It 'Returns disk data from df output' {
            $result = @(Get-DiskInfo)
            $result.Count | Should -BeGreaterOrEqual 1
        }
    }
}

