BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-GpuInfo.ps1"
}

Describe 'Get-GpuInfo' {
    Context 'On any platform' {
        It 'Returns one or more objects' {
            $result = @(Get-GpuInfo)
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Each object has expected properties' {
            $result = @(Get-GpuInfo)
            foreach ($gpu in $result) {
                $gpu.PSObject.Properties.Name | Should -Contain 'Name'
                $gpu.PSObject.Properties.Name | Should -Contain 'DriverVersion'
                $gpu.PSObject.Properties.Name | Should -Contain 'MemoryGB'
            }
        }
    }

    Context 'Mocked as Linux with lspci' -Skip:(-not $IsLinux) {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Invoke-PlatformCommand {
                param($Command)
                if ($Command -eq 'lspci') {
                    return @('00:02.0 VGA compatible controller: Intel UHD Graphics 630')
                }
                if ($Command -eq 'nvidia-smi') { return $null }
                return $null
            }
        }

        It 'Parses lspci output for GPU name' {
            $result = @(Get-GpuInfo)
            $result.Count | Should -Be 1
            $result[0].Name | Should -Match 'Intel'
        }
    }

    Context 'No GPU detected' -Skip:(-not $IsLinux) {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Invoke-PlatformCommand { return $null }
        }

        It 'Returns Unknown fallback' {
            $result = @(Get-GpuInfo)
            $result[0].Name | Should -Be 'Unknown'
        }
    }
}

