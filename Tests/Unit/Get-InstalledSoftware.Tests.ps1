BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
    . "$PSScriptRoot/../../Private/Invoke-PlatformCommand.ps1"
    . "$PSScriptRoot/../../Public/Get-InstalledSoftware.ps1"
}

Describe 'Get-InstalledSoftware' {
    Context 'On any platform' {
        It 'Returns one or more objects' {
            $result = @(Get-InstalledSoftware)
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Each object has expected properties' {
            $result = @(Get-InstalledSoftware)
            foreach ($sw in $result | Select-Object -First 5) {
                $sw.PSObject.Properties.Name | Should -Contain 'Name'
                $sw.PSObject.Properties.Name | Should -Contain 'Version'
                $sw.PSObject.Properties.Name | Should -Contain 'Source'
            }
        }
    }

    Context 'Mocked as Linux with dpkg' {
        BeforeAll {
            Mock Get-PlatformType { return 'Linux' }
            Mock Invoke-PlatformCommand {
                param($Command)
                if ($Command -eq 'dpkg-query') {
                    return @(
                        "vim`t8.2.0"
                        "curl`t7.81.0"
                        "git`t2.34.1"
                    )
                }
                return $null
            }
        }

        It 'Parses dpkg output correctly' {
            $result = @(Get-InstalledSoftware)
            $result.Count | Should -Be 3
            ($result | Where-Object Name -eq 'git').Version | Should -Be '2.34.1'
        }

        It 'Results are sorted by Name' {
            $result = @(Get-InstalledSoftware)
            $result[0].Name | Should -Be 'curl'
            $result[-1].Name | Should -Be 'vim'
        }
    }
}

