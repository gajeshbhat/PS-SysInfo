# Contributing to PS-SysInfo

## How to Contribute

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Add or update tests for your changes
5. Run the full test suite and ensure all tests pass
6. Submit a pull request

## Pull Request Guidelines

- Keep PRs focused — one feature or fix per PR
- All new public functions need Pester tests
- Follow the existing code style (verb-noun naming, comment-based help)
- Cross-platform support is required — test on or account for Windows, Linux, and macOS
- Fill out the PR template

## Reporting Bugs

Open an issue using the bug report template. Include your OS, PowerShell version (`$PSVersionTable`), and steps to reproduce.

## Code Style

- Use approved PowerShell verbs (`Get-Verb` to list them)
- Include `[CmdletBinding()]` and `[OutputType()]` on all functions
- Add a `.SYNOPSIS` and `.EXAMPLE` in comment-based help
- Keep functions focused and small

