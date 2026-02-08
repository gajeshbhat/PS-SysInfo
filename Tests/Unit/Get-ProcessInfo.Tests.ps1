BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-ProcessInfo.ps1"
}

Describe 'Get-ProcessInfo' {
    Context 'On any platform' {
        It 'Returns a PSCustomObject' {
            $result = Get-ProcessInfo
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Has expected properties' {
            $result = Get-ProcessInfo
            $result.PSObject.Properties.Name | Should -Contain 'TotalCount'
            $result.PSObject.Properties.Name | Should -Contain 'TopByCpu'
            $result.PSObject.Properties.Name | Should -Contain 'TopByMemory'
        }

        It 'TotalCount is greater than 0' {
            $result = Get-ProcessInfo
            $result.TotalCount | Should -BeGreaterThan 0
        }

        It 'TopByCpu has up to 5 entries' {
            $result = Get-ProcessInfo
            $result.TopByCpu.Count | Should -BeLessOrEqual 5
            $result.TopByCpu.Count | Should -BeGreaterThan 0
        }

        It 'TopByCpu entries have expected properties' {
            $result = Get-ProcessInfo
            $first = $result.TopByCpu[0]
            $first.PSObject.Properties.Name | Should -Contain 'Name'
            $first.PSObject.Properties.Name | Should -Contain 'Id'
            $first.PSObject.Properties.Name | Should -Contain 'CpuSeconds'
            $first.PSObject.Properties.Name | Should -Contain 'MemoryMB'
        }

        It 'Respects TopN parameter' {
            $result = Get-ProcessInfo -TopN 2
            $result.TopByCpu.Count | Should -BeLessOrEqual 2
        }
    }
}

