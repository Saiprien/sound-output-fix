$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -eq 'Core') { throw 'Run this build using Windows PowerShell 5.1 (powershell.exe).' }
$root = $PSScriptRoot
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$automation = Join-Path $env:WINDIR 'Microsoft.Net\assembly\GAC_MSIL\System.Management.Automation\v4.0_3.0.0.0__31bf3856ad364e35\System.Management.Automation.dll'
# Compile in separate processes so loaded libraries do not lock subsequent builds.
& $csc /nologo /target:library "/out:$root\WindowsAudio.dll" "$root\WindowsAudio.cs"
if ($LASTEXITCODE) { throw 'Audio library build failed.' }
$tokens = $null; $errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'ModernControls.ps1'), [ref]$tokens, [ref]$errors)
if ($errors) { throw ($errors | Out-String) }
$source = $ast.Find({param($node) $node -is [Management.Automation.Language.StringConstantExpressionAst] -and $node.Value.Contains('public class SmoothIndicatorPanel')}, $true).Value
if (!$source) { throw 'Controls source was not found.' }
$tempSource = Join-Path $root 'Controls.build.cs'
try {
    [IO.File]::WriteAllText($tempSource, $source)
    & $csc /nologo /target:library /reference:System.Windows.Forms.dll /reference:System.Drawing.dll "/out:$root\ModernControls.dll" $tempSource
    if ($LASTEXITCODE) { throw 'Controls library build failed.' }
} finally { Remove-Item -LiteralPath $tempSource -ErrorAction SilentlyContinue }
& $csc /nologo /target:winexe /platform:x64 "/out:$root\SoundOutputFix.exe" "/win32icon:$root\assets\user-app-icon.ico" "/reference:$automation" /reference:System.Windows.Forms.dll "$root\ExecutableHost.cs"
if ($LASTEXITCODE) { throw 'Executable build failed.' }
Write-Output 'Build complete: SoundOutputFix.exe'