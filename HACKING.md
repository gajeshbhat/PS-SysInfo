# Hacking on PS-SysInfo

## Prerequisites

- PowerShell 7.0+
- Pester 5.7.1

```powershell
Install-Module -Name Pester -RequiredVersion 5.7.1 -Force -Scope CurrentUser
```

## Project Structure

```
PS-SysInfo.psd1       Module manifest
PS-SysInfo.psm1       Root module — dot-sources Private/ and Public/
Private/              Internal helper functions (not exported)
Public/               Exported functions (one per file)
Tests/Unit/           Unit tests with mocks
Tests/Integration/    Module loading and end-to-end tests
```

## Running Tests

```powershell
# Full suite
$config = & ./.pester.ps1; Invoke-Pester -Configuration $config

# Single test file
Invoke-Pester -Path ./Tests/Unit/Get-CpuInfo.Tests.ps1 -Output Detailed

# Unit tests only
Invoke-Pester -Path ./Tests/Unit -Output Detailed
```

## Adding a New Function

1. Create `Public/Get-YourThing.ps1` with platform switch logic
2. Add the function name to `FunctionsToExport` in `PS-SysInfo.psd1`
3. Add it to the `$sectionMap` in `Public/Get-SysInfo.ps1` if it's a new section
4. Update the `ValidateSet` on the `-Section` parameter in `Get-SysInfo`
5. Create `Tests/Unit/Get-YourThing.Tests.ps1`
6. Run the full test suite

