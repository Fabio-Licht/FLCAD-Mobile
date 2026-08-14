param(
  [string]$TestPath = "test",
  [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"
$flutter = if ($env:FLUTTER_ROOT) {
  Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"
} else {
  "flutter"
}

Write-Host "TEST RUNNER"
Write-Host "Loading package..."
$files = Get-ChildItem $TestPath -Recurse -Filter "*_test.dart" | Sort-Object FullName
Write-Host "Import completed"
Write-Host "Bootstrap ready"
Write-Host "Tests discovered: $($files.Count)"

foreach ($file in $files) {
  $relative = Resolve-Path -Relative $file.FullName
  $timer = [Diagnostics.Stopwatch]::StartNew()
  $stdout = New-TemporaryFile
  $stderr = New-TemporaryFile
  try {
    $process = Start-Process $flutter `
      -ArgumentList @("test", "--no-pub", "--machine", $relative) `
      -PassThru -NoNewWindow `
      -RedirectStandardOutput $stdout.FullName `
      -RedirectStandardError $stderr.FullName
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
      $process.Kill($true)
      throw "TIMEOUT after ${TimeoutSeconds}s: $relative"
    }
    $process.WaitForExit()
    $process.Refresh()
    $exitCode = $process.ExitCode
    $events = Get-Content $stdout.FullName
    $first = $events | Select-Object -First 1
    $last = $events | Select-Object -Last 1
    Write-Host "Running first test: $relative"
    Write-Host "  first-event-ms=$($timer.ElapsedMilliseconds)"
    Write-Host "  first=$first"
    Write-Host "  last=$last"
    if ($last -notmatch '"type":"done"' -or $last -notmatch '"success":true') {
      throw "FAILED ($exitCode): $relative; last event: $last"
    }
  } finally {
    Remove-Item $stdout.FullName, $stderr.FullName -Force
  }
}
