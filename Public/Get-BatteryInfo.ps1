function Get-BatteryInfo {
    <#
    .SYNOPSIS
        Returns battery information as a PSCustomObject, or $null if no battery.
    .DESCRIPTION
        Collects battery status, charge percent, and whether charging.
        Works cross-platform. Pipe to ConvertTo-Json for JSON output.
    .EXAMPLE
        Get-BatteryInfo
        Get-BatteryInfo | ConvertTo-Json
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    $platform = Get-PlatformType

    switch ($platform) {
        'Windows' {
            $bat = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
            if (-not $bat) {
                return [PSCustomObject]@{ Present = $false; ChargePercent = 0; IsCharging = $false; Status = 'No battery' }
            }
            $charging = $bat.BatteryStatus -in @(2, 6, 7, 8, 9)
            [PSCustomObject]@{
                Present       = $true
                ChargePercent = [int]($bat.EstimatedChargeRemaining ?? 0)
                IsCharging    = $charging
                Status        = if ($charging) { 'Charging' } else { 'Discharging' }
            }
        }
        'Linux' {
            $batPath = '/sys/class/power_supply/BAT0'
            if (-not (Test-Path $batPath)) {
                return [PSCustomObject]@{ Present = $false; ChargePercent = 0; IsCharging = $false; Status = 'No battery' }
            }
            $capacity = 0
            if (Test-Path "$batPath/capacity") {
                $capacity = [int](Get-Content "$batPath/capacity" -ErrorAction SilentlyContinue)
            }
            $status = 'Unknown'
            if (Test-Path "$batPath/status") {
                $status = (Get-Content "$batPath/status" -ErrorAction SilentlyContinue).Trim()
            }
            [PSCustomObject]@{
                Present       = $true
                ChargePercent = $capacity
                IsCharging    = $status -eq 'Charging'
                Status        = $status
            }
        }
        'macOS' {
            $pmOutput = Invoke-PlatformCommand 'pmset' @('-g', 'batt') 2>/dev/null
            if (-not $pmOutput -or "$pmOutput" -notmatch '(\d+)%') {
                return [PSCustomObject]@{ Present = $false; ChargePercent = 0; IsCharging = $false; Status = 'No battery' }
            }
            $pct = [int]$Matches[1]
            $charging = "$pmOutput" -match 'charging'
            [PSCustomObject]@{
                Present       = $true
                ChargePercent = $pct
                IsCharging    = $charging -and ("$pmOutput" -notmatch 'discharging')
                Status        = if ($charging -and "$pmOutput" -notmatch 'discharging') { 'Charging' } else { 'Discharging' }
            }
        }
        default {
            [PSCustomObject]@{ Present = $false; ChargePercent = 0; IsCharging = $false; Status = 'Unknown' }
        }
    }
}

