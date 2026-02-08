function Invoke-PlatformCommand {
    <#
    .SYNOPSIS
        Safely invokes a platform-specific command and returns its output.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string[]]$Arguments
    )

    try {
        $cmd = Get-Command $Command -ErrorAction Stop
        if ($Arguments) {
            & $cmd @Arguments
        }
        else {
            & $cmd
        }
    }
    catch {
        Write-Verbose "Command '$Command' not available: $_"
        $null
    }
}

