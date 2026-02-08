@{
    RootModule        = 'PS-SysInfo.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a3f7b2c1-4d5e-6f78-9a0b-1c2d3e4f5a6b'
    Author            = 'Gajesh Bhat'
    Description       = 'Cross-platform system information module for PowerShell 7+. Returns structured objects easily convertible to JSON.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-SysInfo'
        'Get-CpuInfo'
        'Get-MemoryInfo'
        'Get-DiskInfo'
        'Get-NetworkInfo'
        'Get-OsInfo'
        'Get-ProcessInfo'
        'Get-GpuInfo'
        'Get-BatteryInfo'
        'Get-InstalledSoftware'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData        = @{
        PSData = @{
            Tags       = @('SystemInfo', 'CrossPlatform', 'JSON', 'Monitoring')
            LicenseUri = 'https://www.gnu.org/licenses/gpl-3.0.txt'
            ProjectUri = 'https://github.com/gajeshbhat/PS-SysInfo'
        }
    }
}

