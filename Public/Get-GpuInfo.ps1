function Get-GpuInfo {
    <#
    .SYNOPSIS
        Returns GPU information as an array of PSCustomObjects.
    .DESCRIPTION
        Collects GPU name, driver version, and memory where available.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-GpuInfo
        Get-GpuInfo | ConvertTo-Json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $platform = Get-PlatformType
    $gpus = @()

    switch ($platform) {
        'Windows' {
            Get-CimInstance -ClassName Win32_VideoController | ForEach-Object {
                $memGB = if ($_.AdapterRAM) { [math]::Round($_.AdapterRAM / 1GB, 2) } else { 0 }
                $gpus += [PSCustomObject]@{
                    Name         = $_.Name
                    DriverVersion = $_.DriverVersion
                    MemoryGB     = $memGB
                }
            }
        }
        'Linux' {
            # Try lspci for GPU names
            $lspci = Invoke-PlatformCommand 'lspci' 2>/dev/null
            if ($lspci) {
                $vgaLines = $lspci | Where-Object { $_ -match 'VGA|3D|Display' }
                foreach ($line in $vgaLines) {
                    $name = if ($line -match ':\s+(.+)$') { $Matches[1] } else { $line }
                    $gpus += [PSCustomObject]@{
                        Name          = $name.Trim()
                        DriverVersion = 'N/A'
                        MemoryGB      = 0
                    }
                }
            }
            # Try nvidia-smi for NVIDIA details
            $nvSmi = Invoke-PlatformCommand 'nvidia-smi' @('--query-gpu=name,driver_version,memory.total', '--format=csv,noheader,nounits') 2>/dev/null
            if ($nvSmi) {
                $gpus = @() # replace lspci data with richer nvidia data
                foreach ($line in $nvSmi) {
                    $parts = $line -split ',\s*'
                    if ($parts.Count -ge 3) {
                        $gpus += [PSCustomObject]@{
                            Name          = $parts[0].Trim()
                            DriverVersion = $parts[1].Trim()
                            MemoryGB      = [math]::Round([double]$parts[2] / 1024, 2)
                        }
                    }
                }
            }
        }
        'macOS' {
            $spOutput = Invoke-PlatformCommand 'system_profiler' @('SPDisplaysDataType') 2>/dev/null
            if ($spOutput) {
                $currentGpu = $null
                foreach ($line in $spOutput) {
                    if ($line -match '^\s{4}(\S.+):$') {
                        if ($currentGpu) { $gpus += $currentGpu }
                        $currentGpu = [PSCustomObject]@{ Name = $Matches[1].Trim(); DriverVersion = 'N/A'; MemoryGB = 0 }
                    }
                    if ($currentGpu -and $line -match 'VRAM.*?:\s*(\d+)\s*(MB|GB)') {
                        $val = [double]$Matches[1]
                        $currentGpu.MemoryGB = if ($Matches[2] -eq 'GB') { $val } else { [math]::Round($val / 1024, 2) }
                    }
                }
                if ($currentGpu) { $gpus += $currentGpu }
            }
        }
    }

    if ($gpus.Count -eq 0) {
        $gpus += [PSCustomObject]@{ Name = 'Unknown'; DriverVersion = 'N/A'; MemoryGB = 0 }
    }
    $gpus
}

