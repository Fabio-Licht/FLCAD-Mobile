param(
  [string]$Mesh = 'C:\TRABALHO\MAHA 3D\CALOTA_INOXX\CALOTA_INOXX.stl',
  [string]$Output = 'C:\flcad_mobile\smoke\r2-002-video\r2-002-visual-validation-raw.mp4'
)

$ErrorActionPreference = 'Stop'
$ffmpeg = (Get-ChildItem 'C:\flcad_mobile\build\tools\ffmpeg' -Filter ffmpeg.exe -Recurse |
  Select-Object -First 1).FullName
$executable = 'C:\flcad_mobile\build\render_lab\Release\FLCAD Render Lab.exe'
New-Item -ItemType Directory -Path (Split-Path $Output) -Force | Out-Null

$recorder = Start-Process -FilePath $ffmpeg -WindowStyle Hidden -PassThru -ArgumentList @(
  '-y', '-f', 'gdigrab', '-framerate', '30', '-draw_mouse', '1',
  '-offset_x', '0', '-offset_y', '0', '-video_size', '1280x720',
  '-i', 'desktop', '-t', '34', '-c:v', 'libx264', '-preset', 'ultrafast',
  '-crf', '18', '-pix_fmt', 'yuv420p', $Output
)
Start-Sleep -Seconds 1
$application = Start-Process -FilePath $executable -PassThru
Start-Sleep -Seconds 2

$shell = New-Object -ComObject WScript.Shell
$shell.AppActivate($application.Id) | Out-Null
$shell.SendKeys('%n')
Start-Sleep -Milliseconds 300
$shell.SendKeys($Mesh)
Start-Sleep -Milliseconds 300
$shell.SendKeys('{ENTER}')
Start-Sleep -Seconds 8
$application.Refresh()

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class R2VideoInput {
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int z, bool repaint);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
}
'@

$handle = [IntPtr]$application.MainWindowHandle
[R2VideoInput]::MoveWindow($handle, 0, 0, 1280, 720, $true) | Out-Null
$shell.AppActivate($application.Id) | Out-Null

function Invoke-MouseDrag(
  [uint32]$buttonDown,
  [uint32]$buttonUp,
  [int]$x1,
  [int]$y1,
  [int]$x2,
  [int]$y2
) {
  [R2VideoInput]::SetCursorPos($x1, $y1) | Out-Null
  Start-Sleep -Milliseconds 300
  [R2VideoInput]::mouse_event($buttonDown, 0, 0, 0, [UIntPtr]::Zero)
  for ($step = 1; $step -le 24; $step++) {
    [R2VideoInput]::SetCursorPos(
      [int]($x1 + ($x2 - $x1) * $step / 24),
      [int]($y1 + ($y2 - $y1) * $step / 24)
    ) | Out-Null
    Start-Sleep -Milliseconds 55
  }
  [R2VideoInput]::mouse_event($buttonUp, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 500
}

# Orbit, then Pan.
Invoke-MouseDrag 0x0002 0x0004 640 360 790 425
Invoke-MouseDrag 0x0020 0x0040 640 360 550 400

# Zoom in and out.
[R2VideoInput]::SetCursorPos(640, 360) | Out-Null
for ($index = 0; $index -lt 5; $index++) {
  [R2VideoInput]::mouse_event(0x0800, 0, 0, 120, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 240
}
$wheelDown = [BitConverter]::ToUInt32([BitConverter]::GetBytes([int]-120), 0)
for ($index = 0; $index -lt 3; $index++) {
  [R2VideoInput]::mouse_event(0x0800, 0, 0, $wheelDown, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 240
}

# Fit.
Start-Sleep -Milliseconds 400
$shell.AppActivate($application.Id) | Out-Null
$shell.SendKeys('f')
Start-Sleep -Seconds 2

# Resize down and restore progressively.
for ($step = 0; $step -le 10; $step++) {
  [R2VideoInput]::MoveWindow($handle, 0, 0, 1280 - $step * 28, 720 - $step * 16, $true) | Out-Null
  Start-Sleep -Milliseconds 90
}
Start-Sleep -Milliseconds 600
for ($step = 10; $step -ge 0; $step--) {
  [R2VideoInput]::MoveWindow($handle, 0, 0, 1280 - $step * 28, 720 - $step * 16, $true) | Out-Null
  Start-Sleep -Milliseconds 90
}
Start-Sleep -Seconds 3

$application.Refresh()
$renderTitle = $application.MainWindowTitle
$closeRequested = $application.CloseMainWindow()
$application.WaitForExit(5000) | Out-Null
$recorder.WaitForExit(15000) | Out-Null

[pscustomobject]@{
  RawVideo = $Output
  Bytes = (Get-Item $Output).Length
  RenderTitle = $renderTitle
  AppCloseRequested = $closeRequested
  AppExited = $application.HasExited
  RecorderExited = $recorder.HasExited
  RecorderExitCode = if ($recorder.HasExited) { $recorder.ExitCode } else { $null }
}
