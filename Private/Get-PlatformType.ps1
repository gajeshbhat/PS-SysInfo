function Get-PlatformType {
    <#
    .SYNOPSIS
        Returns the current OS platform: Windows, Linux, or macOS.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($IsWindows) { return 'Windows' }
    if ($IsLinux)   { return 'Linux' }
    if ($IsMacOS)   { return 'macOS' }

    return 'Unknown'
}

