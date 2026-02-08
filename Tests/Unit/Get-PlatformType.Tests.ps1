BeforeAll {
    . "$PSScriptRoot/../../Private/Get-PlatformType.ps1"
}

Describe 'Get-PlatformType' {
    Context 'Matches automatic variables' {
        It 'Returns Windows when running on Windows' -Skip:(-not $IsWindows) {
            Get-PlatformType | Should -Be 'Windows'
        }

        It 'Returns Linux when running on Linux' -Skip:(-not $IsLinux) {
            Get-PlatformType | Should -Be 'Linux'
        }

        It 'Returns macOS when running on macOS' -Skip:(-not $IsMacOS) {
            Get-PlatformType | Should -Be 'macOS'
        }
    }

    Context 'Returns a valid platform string' {
        It 'Returns one of the known platforms' {
            $result = Get-PlatformType
            $result | Should -BeIn @('Windows', 'Linux', 'macOS', 'Unknown')
        }

        It 'Returns a non-empty string' {
            $result = Get-PlatformType
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

