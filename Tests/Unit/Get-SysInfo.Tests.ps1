BeforeAll {
    # Load entire module
    Import-Module "$PSScriptRoot/../../PS-SysInfo.psd1" -Force
}

AfterAll {
    Remove-Module PS-SysInfo -ErrorAction SilentlyContinue
}

Describe 'Get-SysInfo' {
    Context 'Full output (no filters)' {
        It 'Returns a PSCustomObject' {
            $result = Get-SysInfo
            $result | Should -BeOfType [PSCustomObject]
        }

        It 'Has Timestamp and Platform' {
            $result = Get-SysInfo
            $result.Timestamp | Should -Not -BeNullOrEmpty
            $result.Platform | Should -BeIn @('Windows', 'Linux', 'macOS', 'Unknown')
        }

        It 'Contains all default sections' {
            $result = Get-SysInfo
            $expected = @('Cpu', 'Memory', 'Disk', 'Network', 'Os', 'Processes', 'Gpu', 'Battery', 'Software')
            foreach ($sec in $expected) {
                $result.PSObject.Properties.Name | Should -Contain $sec
            }
        }
    }

    Context 'Section filtering' {
        It 'Returns only requested sections' {
            $result = Get-SysInfo -Section Cpu, Memory
            $result.PSObject.Properties.Name | Should -Contain 'Cpu'
            $result.PSObject.Properties.Name | Should -Contain 'Memory'
            $result.PSObject.Properties.Name | Should -Not -Contain 'Disk'
            $result.PSObject.Properties.Name | Should -Not -Contain 'Network'
        }

        It 'Single section works' {
            $result = Get-SysInfo -Section Os
            $result.Os | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Not -Contain 'Cpu'
        }
    }

    Context 'Property filtering' {
        It 'Filters properties on single-object sections' {
            $result = Get-SysInfo -Section Os -Property Name, Version
            $result.Os.PSObject.Properties.Name | Should -Contain 'Name'
            $result.Os.PSObject.Properties.Name | Should -Contain 'Version'
            $result.Os.PSObject.Properties.Name | Should -Not -Contain 'Hostname'
        }
    }

    Context 'JSON conversion' {
        It 'Converts to valid JSON' {
            $json = Get-SysInfo -Section Os | ConvertTo-Json -Depth 5
            { $json | ConvertFrom-Json } | Should -Not -Throw
        }
    }
}

