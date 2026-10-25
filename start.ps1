param([int]$Port=8080,[string]$BindAddress='127.0.0.1',[switch]$Rebuild)
$ErrorActionPreference='Stop'
$projectRoot=$PSScriptRoot
$toolsRoot=Join-Path $env:USERPROFILE 'Documents\Codex\tools'
$toolsRoot=[System.IO.Path]::GetFullPath($toolsRoot)
$flutterCommand=Join-Path $toolsRoot 'flutter\bin\flutter.bat'
if(-not (Test-Path -LiteralPath $flutterCommand)){
  $flutterCommand=(Get-Command flutter -ErrorAction Stop).Source
}
$dartCommand=Join-Path (Split-Path $flutterCommand -Parent) 'cache\dart-sdk\bin\dart.exe'
$env:PUB_CACHE=Join-Path $toolsRoot 'pub-cache'
$env:GRADLE_USER_HOME=Join-Path $toolsRoot 'gradle-cache'
$env:ANDROID_USER_HOME=Join-Path $toolsRoot 'android-user'
$env:APPDATA=Join-Path $toolsRoot 'flutter-config'
$env:TEMP=Join-Path $projectRoot '.scratch'
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Path $env:TEMP,$env:APPDATA -Force | Out-Null
Push-Location $projectRoot
try {
  if($Rebuild -or -not (Test-Path -LiteralPath 'build\web\index.html')) {
    & $flutterCommand pub get
    if($LASTEXITCODE -ne 0){throw 'Flutter dependency download failed.'}
    & $flutterCommand build web
    if($LASTEXITCODE -ne 0){throw 'Web build failed.'}
  }
  Set-Location (Join-Path $projectRoot 'server')
  & $dartCommand pub get
  if($LASTEXITCODE -ne 0){throw 'Server dependency download failed.'}
  $env:FIVE_PORT="$Port"
  $env:FIVE_HOST=$BindAddress
  if(-not (Test-Path -LiteralPath 'data\campaign.db')) {
    $env:FIVE_DM_USER=Read-Host 'Choose the DM username (2-40 characters)'
    $passwordSecure=Read-Host 'Choose the DM password (at least 12 characters)' -AsSecureString
    $passwordPtr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure)
    try {$env:FIVE_DM_PASSWORD=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPtr)}
    finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPtr)}
  }
  Write-Host "Open http://localhost:$Port in your browser. Press Ctrl+C to stop."
  & $dartCommand run bin\server.dart
} finally {
  Remove-Item Env:FIVE_DM_PASSWORD -ErrorAction SilentlyContinue
  Pop-Location
}
