# PS-SysInfo

Cross-platform PowerShell 7+ module that collects system information and returns structured objects easily convertible to JSON.

## Install

```powershell
Install-Module -Name PS-SysInfo
```

## Usage

```powershell
Import-Module PS-SysInfo

# Full system info as JSON
Get-SysInfo | ConvertTo-Json -Depth 5

# Specific sections only
Get-SysInfo -Section Cpu, Memory, Os | ConvertTo-Json -Depth 5

# Filter properties within a section
Get-SysInfo -Section Os -Property Name, Version | ConvertTo-Json -Depth 5

# Individual functions
Get-CpuInfo | ConvertTo-Json
Get-MemoryInfo | ConvertTo-Json
Get-DiskInfo | ConvertTo-Json
Get-NetworkInfo | ConvertTo-Json -Depth 3
Get-OsInfo | ConvertTo-Json
Get-ProcessInfo | ConvertTo-Json -Depth 3
Get-GpuInfo | ConvertTo-Json
Get-BatteryInfo | ConvertTo-Json
Get-InstalledSoftware | ConvertTo-Json
```

### Available Sections

`Cpu`, `Memory`, `Disk`, `Network`, `Os`, `Processes`, `Gpu`, `Battery`, `Software`

## Requirements

- PowerShell 7.0 or later

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute and [HACKING.md](HACKING.md) for development setup.

## License

[GPLv3](LICENSE)

