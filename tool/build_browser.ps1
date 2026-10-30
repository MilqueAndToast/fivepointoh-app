param([string]$Flutter = 'flutter', [string]$BaseHref = '/', [switch]$NoPub)

$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $buildArguments = @('--no-version-check', 'build', 'web', '--release', '--pwa-strategy=none', '--no-source-maps', '--no-web-resources-cdn', '--dart-define=BROWSER_LOCAL_ONLY=true', '--output=dist', "--base-href=$BaseHref")
    if ($NoPub) { $buildArguments += '--no-pub' }
    & $Flutter @buildArguments
    if ($LASTEXITCODE -ne 0) { throw 'Browser build failed.' }
} finally {
    Pop-Location
}
