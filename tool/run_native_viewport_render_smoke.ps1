param([ValidateSet('Debug', 'Release')][string]$Configuration = 'Release')

$ErrorActionPreference = 'Stop'
$viewportRepo = Split-Path -Parent $PSScriptRoot
$viewportBuild = Join-Path $viewportRepo "build\windows\x64"
$viewportWrapper = Join-Path $viewportBuild "flutter\$Configuration\flutter_wrapper_plugin.lib"
if (-not (Test-Path -LiteralPath $viewportWrapper)) {
    throw "Build Windows $Configuration before running this renderer smoke."
}
$viewportVswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$viewportVs = & $viewportVswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$viewportVcvars = Join-Path $viewportVs 'VC\Auxiliary\Build\vcvars64.bat'
$viewportTemp = Join-Path ([IO.Path]::GetTempPath()) ('flcad-render-smoke-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $viewportTemp | Out-Null
$viewportFlags = if ($Configuration -eq 'Debug') { '/MDd /Zi' } else { '/MD /O2 /DNDEBUG' }
$viewportClient = Join-Path $viewportRepo 'windows\flutter\ephemeral\cpp_client_wrapper\include'
$viewportEngine = Join-Path $viewportRepo 'windows\flutter\ephemeral'
$viewportCamera = Join-Path $viewportRepo 'native\render_engine'
$viewportSource = Join-Path $viewportRepo 'test\native_viewport_render_smoke.cpp'
$viewportExe = Join-Path $viewportTemp 'render-smoke.exe'
$viewportCommand = @"
@echo off
call "$viewportVcvars" >nul
if errorlevel 1 exit /b 1
cl /nologo /std:c++17 /EHsc /DNOMINMAX $viewportFlags /I "$viewportClient" /I "$viewportEngine" /I "$viewportCamera" "$viewportSource" /Fe:"$viewportExe" /link "$viewportWrapper" "$viewportEngine\flutter_windows.dll.lib" d3d11.lib d3dcompiler.lib dxgi.lib
exit /b %errorlevel%
"@
$viewportCmdFile = Join-Path $viewportTemp 'compile.cmd'
Set-Content -LiteralPath $viewportCmdFile -Value $viewportCommand -Encoding ASCII
Push-Location $viewportTemp
$viewportOriginalPath = $env:PATH
try {
    & cmd.exe /c $viewportCmdFile
    if ($LASTEXITCODE -ne 0) { throw 'Renderer smoke compilation failed.' }
    $env:PATH = (Join-Path $viewportBuild "runner\$Configuration") + ';' + $env:PATH
    & $viewportExe
    if ($LASTEXITCODE -ne 0) { throw 'Renderer smoke failed.' }
} finally {
    $env:PATH = $viewportOriginalPath
    Pop-Location
}
