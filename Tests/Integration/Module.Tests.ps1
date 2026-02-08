BeforeAll {
    $modulePath = "$PSScriptRoot/../../PS-SysInfo.psd1"
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module PS-SysInfo -ErrorAction SilentlyContinue
}

Describe 'PS-SysInfo Module' {
    Context 'Module loading' {
        It 'Module is loaded' {
            Get-Module PS-SysInfo | Should -Not -BeNullOrEmpty
        }

        It 'Requires PowerShell 7+' {
            $manifest = Test-ModuleManifest "$PSScriptRoot/../../PS-SysInfo.psd1"
            $manifest.PowerShellVersion | Should -Be '7.0'
        }
    }

    Context 'Exported functions' {
        It 'Exports Get-SysInfo' {
            Get-Command Get-SysInfo -Module PS-SysInfo | Should -Not -BeNullOrEmpty
        }

        It 'Exports all expected public functions' {
            $expected = @(
                'Get-SysInfo', 'Get-CpuInfo', 'Get-MemoryInfo', 'Get-DiskInfo',
                'Get-NetworkInfo', 'Get-OsInfo', 'Get-ProcessInfo',
                'Get-GpuInfo', 'Get-BatteryInfo', 'Get-InstalledSoftware'
            )
            $exported = (Get-Module PS-SysInfo).ExportedFunctions.Keys
            foreach ($fn in $expected) {
                $exported | Should -Contain $fn
            }
        }

        It 'Does not export private functions' {
            $exported = (Get-Module PS-SysInfo).ExportedFunctions.Keys
            $exported | Should -Not -Contain 'Get-PlatformType'
            $exported | Should -Not -Contain 'Invoke-PlatformCommand'
        }
    }

    Context 'End-to-end JSON output' {
        It 'Full Get-SysInfo produces valid JSON' {
            $json = Get-SysInfo | ConvertTo-Json -Depth 5
            $parsed = $json | ConvertFrom-Json
            $parsed.Platform | Should -Not -BeNullOrEmpty
            $parsed.Timestamp | Should -Not -BeNullOrEmpty
        }

        It 'Filtered Get-SysInfo produces valid JSON' {
            $json = Get-SysInfo -Section Cpu, Os | ConvertTo-Json -Depth 5
            $parsed = $json | ConvertFrom-Json
            $parsed.Cpu | Should -Not -BeNullOrEmpty
            $parsed.Os | Should -Not -BeNullOrEmpty
        }

        It 'Individual functions produce valid JSON' {
            $functions = @('Get-CpuInfo', 'Get-MemoryInfo', 'Get-OsInfo',
                           'Get-BatteryInfo', 'Get-ProcessInfo')
            foreach ($fn in $functions) {
                $json = & $fn | ConvertTo-Json -Depth 3
                { $json | ConvertFrom-Json } | Should -Not -Throw
            }
        }

        It 'Array-returning functions produce valid JSON' {
            $functions = @('Get-DiskInfo', 'Get-NetworkInfo', 'Get-GpuInfo', 'Get-InstalledSoftware')
            foreach ($fn in $functions) {
                $json = @(& $fn) | ConvertTo-Json -Depth 3
                { $json | ConvertFrom-Json } | Should -Not -Throw
            }
        }
    }
}

