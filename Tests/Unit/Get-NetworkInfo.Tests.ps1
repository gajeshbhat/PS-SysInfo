BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-NetworkInfo.ps1"
}

Describe 'Get-NetworkInfo' {
    Context 'On any platform' {
        It 'Returns one or more objects' {
            $result = @(Get-NetworkInfo)
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Each object has expected properties' {
            $result = @(Get-NetworkInfo)
            $expected = @('Name', 'MacAddress', 'IPv4', 'IPv6', 'Status')
            foreach ($nic in $result) {
                foreach ($prop in $expected) {
                    $nic.PSObject.Properties.Name | Should -Contain $prop
                }
            }
        }

        It 'Name is not empty for first adapter' {
            $result = @(Get-NetworkInfo)
            $result[0].Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Mocked as Linux' -Skip:(-not $IsLinux) {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
        }

        It 'Returns network adapter data' {
            $result = @(Get-NetworkInfo)
            $result.Count | Should -BeGreaterOrEqual 1
        }
    }
}

